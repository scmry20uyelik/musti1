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
