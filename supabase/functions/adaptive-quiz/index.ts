// Adaptive quiz generator using Google Gemini (gemini-2.5-flash)
import { serve } from 'std/server'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
if (!GEMINI_API_KEY) console.warn('GEMINI_API_KEY not set')

async function callGemini(prompt: string) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`
  const body = {
    "prompt": {
      "text": prompt
    },
    "temperature": 0.2,
    "maxOutputTokens": 512
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

function buildPrompt(level: string, topic: string) {
  return `Create a concise adaptive quiz for German learners. Output in JSON matching this schema: {\n  "quizId":"<unique>",\n  "level":"${level}",\n  "topic":"${topic}",\n  "questions":[{\n    \"id\":\"q1\",\n    \"type\":\"multiple_choice\",\n    \"question\":\"Provide a question text\",\n    \"options\":[{\"id\":\"a\",\"text\":\"...\",\"correct\":false}],\n    \"difficulty\":1\n  }],\n  \"meta\":{\"generatedBy\":\"gemini-2.5-flash\"}\n}\nMake sure JSON is valid and do not include extra commentary.`
}

serve(async (req) => {
  try {
    const { level, topic } = await req.json()
    const prompt = buildPrompt(level || 'Genel', topic || 'Genel')
    const resp = await callGemini(prompt)

    // Best-effort parse the content (varies by Gemini response shape)
    const content = resp?.candidates?.[0]?.content?.[0]?.text || resp?.candidates?.[0]?.output || JSON.stringify(resp)

    // Attempt to parse JSON from Gemini text
    let quiz
    try {
      quiz = JSON.parse(content)
    } catch (e) {
      // If parsing fails, wrap into fallback structure
      quiz = {
        quizId: `fallback-${Date.now()}`,
        level: level,
        topic: topic,
        questions: [
          {
            id: 'fallback-1',
            type: 'multiple_choice',
            question: 'Fallback: Was ist die Übersetzung für "Haus"?',
            options: [
              { id: 'a', text: 'Ev', correct: true },
              { id: 'b', text: 'Araba', correct: false }
            ],
            difficulty: 1
          }
        ],
        meta: { generatedBy: 'gemini-2.5-flash', note: 'fallback because parse failed' }
      }
    }

    return new Response(JSON.stringify(quiz), { status: 200, headers: { 'content-type': 'application/json' } })
  } catch (e) {
    console.error('adaptive-quiz error', e)
    return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: { 'content-type': 'application/json' } })
  }
})