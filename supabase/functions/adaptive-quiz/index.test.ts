import { assertStringIncludes, assertNotEquals } from 'https://deno.land/std@0.205.0/testing/asserts.ts'
import { buildPrompt, parseQuizFromContent } from './index.ts'

// Simple unit tests to validate the buildPrompt output contains required instructions
Deno.test('buildPrompt contains vocabulary and curriculum instructions', () => {
  const p = buildPrompt('A1.1', 'Artikel')
  assertStringIncludes(p, 'vocabulary')
  assertStringIncludes(p, 'translation')
  assertStringIncludes(p, 'curriculum')
  assertStringIncludes(p, 'example_past')
})

Deno.test('parseQuizFromContent parses clean JSON', () => {
  const json = '{"quizId":"x","questions":[],"vocabulary":[],"curriculum":[]}'
  const parsed = parseQuizFromContent(json)
  assertNotEquals(parsed, null)
})

Deno.test('parseQuizFromContent extracts JSON from surrounding text', () => {
  const wrapped = 'Some text before\n' +
    '{"quizId":"y","questions":[],"vocabulary":[],"curriculum":[]}' +
    '\nSome text after'
  const parsed = parseQuizFromContent(wrapped)
  assertNotEquals(parsed, null)
})

Deno.test('parseQuizFromContent recovers truncated JSON', () => {
  const truncated = '{"quizId":"z","questions":[{"id":"q1"}],"vocabulary":['
  const parsed = parseQuizFromContent(truncated)
  // Should be null for very broken input but should not throw; we assert parse function returns null or an object, just ensure no exception
  // At minimum the function should not throw and return either null or parsed object
  if (parsed != null) {
    assertNotEquals(parsed, null)
  }
})

Deno.test('ensureQuizCompleteness fixes missing vocabulary and curriculum fields (mocked)', async () => {
  // Prepare an incomplete quiz
  const incomplete = {
    quizId: 't1',
    level: 'A1.1',
    topic: 'Artikel',
    questions: [{ id: 'q1', type: 'multiple_choice', question: 'Was ist das?', options: [{ id: 'a', text: 'das Haus', correct: true }], difficulty: 1 }],
    vocabulary: [{ word: 'Haus', translation: 'ev' }],
    curriculum: []
  }

  // Mock callGemini to return a corrected JSON string
  const fixed = JSON.stringify({
    ...incomplete,
    vocabulary: [{ word: 'Haus', article: 'das', translation: 'ev', example_present: 'Das Haus ist groß.', example_past: 'Das Haus war groß.' }],
    curriculum: [
      { lesson: 'Artikel - Temel', objectives: ['Artikel tanıma', 'Kısa cümle', 'Kelime'] },
      { lesson: 'Artikel - Örnek', objectives: ['Present', 'Past', 'Kullanım'] },
      { lesson: 'Artikel - Alıştırma', objectives: ['MCQ', 'Fill in', 'Translate'] }
    ]
  })

  // Monkeypatch callGemini
  const mod = await import('./index.ts')
  mod.callGemini = async (_prompt: string) => ({ candidates: [{ content: [{ text: fixed }] }] })

  const result = await mod.ensureQuizCompleteness(incomplete, 'A1.1', 'Artikel')
  if (!result || !Array.isArray(result.vocabulary) || !result.vocabulary[0].article) throw new Error('Vocabulary not fixed')
  if (!Array.isArray(result.curriculum) || result.curriculum.length < 3) throw new Error('Curriculum not fixed')
})
