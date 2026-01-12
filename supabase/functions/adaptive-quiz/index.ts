// Adaptive quiz generator using Google Gemini (gemini-2.5-flash)
import { serve } from 'https://deno.land/std@0.205.0/http/server.ts'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
if (!GEMINI_API_KEY) console.warn('GEMINI_API_KEY not set')

// Validate env shape for production
if (GEMINI_API_KEY && GEMINI_API_KEY.startsWith('sb_')) {
  console.warn('Warning: GEMINI_API_KEY looks like a Supabase secret, make sure you set the correct Gemini API key in secrets')
}

export async function callGemini(prompt: string) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`
  const body = {
    contents: [{ parts: [{ text: prompt }] }],
    // Low temperature to maximize determinism and higher token budget for richer quizzes
    generationConfig: { temperature: 0.0, maxOutputTokens: 1536 }
  }

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  })

  if (!res.ok) {
    const text = await res.text()
    throw new Error(`Gemini API error: ${res.status} ${text}`)
  }

  const json = await res.json()
  return json
}

export function buildPrompt(level: string, topic: string) {
  return `You are an expert German teacher. Create a concise adaptive quiz for German learners focused on the theme: "${topic}" and level "${level}". Treat the topic as a theme and include a short curriculum (3 lessons) that teaches that theme.

Output ONLY a single VALID JSON object (no code fences, no commentary, no extra text). The JSON MUST follow this schema exactly:

{
  "quizId":"<unique>",
  "level":"${level}",
  "topic":"${topic}",
  "questions":[{ "id":"q1","type":"multiple_choice","question":"...","options":[{"id":"a","text":"...","correct":false}],"difficulty":1 }],
  "vocabulary":[{ "word":"Haus","article":"das","translation":"ev","example_present":"Das Haus ist groß.","example_past":"Das Haus war groß." }],
  "curriculum":[{ "lesson":"Lesson title","objectives":["..."] }],
  "meta":{"generatedBy":"gemini-2.5-flash"}
}

Requirements:
- Provide 1–3 focused questions appropriate to the level and theme. Mark the correct option with "correct":true.
- Include a 'vocabulary' array with each item containing: German 'word', correct 'article' (der/die/das), Turkish 'translation', an 'example_present' sentence in German, and an 'example_past' sentence in German (use Präteritum or Perfekt; either is acceptable but be consistent).
- Create a short 'curriculum' array with 3 lessons, each lesson having 'lesson' and 'objectives' (3 concise objectives).
- Keep text short and simple; options should be single words or short phrases when possible.
- Do not include any explanatory text outside the JSON. If you must include additional text, ensure the final line of the response contains ONLY the JSON object.`
}

// Parse a JSON-like string produced by Gemini, with recovery heuristics.
export function parseQuizFromContent(content: string) {
  const firstBrace = content.indexOf('{')
  if (firstBrace < 0) return null
  const lastBrace = content.lastIndexOf('}')
  let candidate = lastBrace > firstBrace ? content.substring(firstBrace, lastBrace + 1) : content.substring(firstBrace)

  // Balance braces if necessary
  const openCount = (candidate.match(/{/g) || []).length
  const closeCount = (candidate.match(/}/g) || []).length
  if (openCount > closeCount) candidate = candidate + '}'.repeat(openCount - closeCount)

  try {
    return JSON.parse(candidate)
  } catch (e) {
    return null
  }
}

// Validate quiz object and attempt to fix missing vocabulary/article/examples/curriculum
export async function ensureQuizCompleteness(quiz: any, level: string, topic: string) {
  const validArticles = ['der', 'die', 'das']

  const isVocabularyValid = (v: any) => {
    if (!v || typeof v !== 'object') return false
    return !!v.word && !!v.article && validArticles.includes((v.article || '').toString().toLowerCase()) && !!v.translation && !!v.example_present && !!v.example_past
  }

  const hasGoodVocab = Array.isArray(quiz.vocabulary) && quiz.vocabulary.length > 0 && quiz.vocabulary.every(isVocabularyValid)
  const hasCurriculum = Array.isArray(quiz.curriculum) && quiz.curriculum.length >= 3 && quiz.curriculum.every((c: any) => c.lesson && Array.isArray(c.objectives) && c.objectives.length >= 1)

  if (hasGoodVocab && hasCurriculum) return quiz

  // Ask Gemini to return a corrected full JSON quiz object with required fields
  const fixPrompt = `You are an expert German teacher. Fix the following JSON quiz so that each item in 'vocabulary' has: 'word', 'article' (one of der/die/das), 'translation' (Turkish), 'example_present', and 'example_past'. Ensure 'curriculum' has 3 lessons with 'lesson' and 3 short 'objectives' each. Return ONLY a single valid JSON object (no extra text):

${JSON.stringify(quiz)}`

  try {
    const resp = await callGemini(fixPrompt)
    const content = resp?.candidates?.[0]?.content?.[0]?.text || resp?.candidates?.[0]?.output || JSON.stringify(resp)
    const parsed = parseQuizFromContent(content)
    if (parsed) {
      const parsedHasGoodVocab = Array.isArray(parsed.vocabulary) && parsed.vocabulary.length > 0 && parsed.vocabulary.every(isVocabularyValid)
      const parsedHasCurriculum = Array.isArray(parsed.curriculum) && parsed.curriculum.length >= 3
      if (parsedHasGoodVocab && parsedHasCurriculum) return parsed
    }
  } catch (e) {
    // ignore and fallback to best-effort
  }

  // Best-effort filling for missing fields
  const fallbackQuiz = JSON.parse(JSON.stringify(quiz))
  fallbackQuiz.vocabulary = fallbackQuiz.vocabulary || []
  if (!Array.isArray(fallbackQuiz.vocabulary)) fallbackQuiz.vocabulary = []
  if (fallbackQuiz.vocabulary.length === 0) {
    fallbackQuiz.vocabulary.push({ word: 'Haus', article: 'das', translation: 'ev', example_present: 'Das Haus ist groß.', example_past: 'Das Haus war groß.' })
  } else {
    fallbackQuiz.vocabulary = fallbackQuiz.vocabulary.map((v: any) => ({
      word: v.word || '---',
      article: validArticles.includes((v.article || '').toString().toLowerCase()) ? v.article : 'das',
      translation: v.translation || '',
      example_present: v.example_present || `Das ${v.word || 'Wort'} ist ... .`,
      example_past: v.example_past || `Das ${v.word || 'Wort'} war ... .`,
    }))
  }

  fallbackQuiz.curriculum = fallbackQuiz.curriculum || []
  if (!Array.isArray(fallbackQuiz.curriculum)) fallbackQuiz.curriculum = []
  while (fallbackQuiz.curriculum.length < 3) {
    fallbackQuiz.curriculum.push({ lesson: `${topic} - Temel`, objectives: ['Artikel kullanımı', 'Örnek cümle', 'Kelime tekrarı'] })
  }

  return fallbackQuiz
}


serve(async (req) => {
  try {
    const { level, topic } = await req.json()
    // Validate GEMINI_API_KEY and give clear error if it's missing or set to a Supabase secret
    if (!GEMINI_API_KEY || GEMINI_API_KEY.startsWith('sb_')) {
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY eksik veya yanlış. Lütfen Supabase secrets içinde gerçek Gemini API anahtarınızı (ör. AI key) ekleyin.' }), { status: 400, headers: { 'content-type': 'application/json' } });
    }

    const prompt = buildPrompt(level || 'Genel', topic || 'Genel')

    // Make an initial call to Gemini
    let resp = await callGemini(prompt)
    let content = resp?.candidates?.[0]?.content?.[0]?.text || resp?.candidates?.[0]?.output || JSON.stringify(resp)

    // Attempt to parse JSON with robust heuristics and up to 2 retries with a clarifying prompt
    let quiz: any = null
    let attempts = 0
    const maxAttempts = 2
    while (!quiz && attempts <= maxAttempts) {
      attempts++

      // Use exported parser to attempt to recover JSON
      quiz = parseQuizFromContent(content)
      if (quiz) break

      if (!quiz && attempts <= maxAttempts) {
        // Ask the model to reply only with the JSON object in a short clarifying prompt
        const clarify = prompt + '\n\nIMPORTANT: Please reply ONLY with the JSON object exactly as requested above (no text, no explanation). If you previously included extra text, repeat only the JSON object now.'
        resp = await callGemini(clarify)
        content = resp?.candidates?.[0]?.content?.[0]?.text || resp?.candidates?.[0]?.output || JSON.stringify(resp)
      }
    }

    if (!quiz) {
      // If parsing fails after retries, return a richer fallback quiz that still meets schema
      quiz = {
        quizId: `fallback-${Date.now()}`,
        level: level,
        topic: topic,
        questions: [
          {
            id: 'fallback-1',
            type: 'multiple_choice',
            question: 'Fallback: Was ist die Übersetzung für "Haus"? (Türkçe: Ev)',
            options: [
              { id: 'a', text: 'Ev', correct: true },
              { id: 'b', text: 'Araba', correct: false }
            ],
            difficulty: 1
          }
        ],
        vocabulary: [
          { word: 'Haus', article: 'das', translation: 'ev', example_present: 'Das Haus ist groß.', example_past: 'Das Haus war groß.' }
        ],
        curriculum: [
          { lesson: `${topic} - Artikel Kullanımı`, objectives: ['Artikel tanıma', 'Kısa cümlelerde artikel kullanma', 'Kelime dağarcığını genişletme'] },
          { lesson: `${topic} - Örnek Cümleler`, objectives: ['Present cümle kurma', 'Past cümle kurma', 'Kelime eşleştirme'] },
          { lesson: `${topic} - Alıştırmalar`, objectives: ['Multiple choice', 'Boşluk doldurma', 'Çeviri pratikleri'] }
        ],
        meta: { generatedBy: 'gemini-2.5-flash', note: 'fallback because parse failed or truncated' }
      }
    } else {
      // quiz parsed - ensure completeness (vocabulary & curriculum). This may call Gemini again to fix missing fields.
      quiz = await ensureQuizCompleteness(quiz, level, topic)
    }

    return new Response(JSON.stringify(quiz), { status: 200, headers: { 'content-type': 'application/json' } })
  } catch (e) {
    console.error('adaptive-quiz error', e)
    return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: { 'content-type': 'application/json' } })
  }
})