// Supabase Edge Function: vocabulary-enricher
// Kelimeyi Google Gemini API ile zenginleştirir

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      )
    }

    const { word } = await req.json()

    if (!word || word.trim() === '') {
      return new Response(
        JSON.stringify({ error: 'Word is required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    const prompt = `Sen bir Almanca kelime analiz asistanısın. "${word}" kelimesini analiz et ve SADECE JSON döndür.

ÖNEMLİ: Markdown formatı kullanma! Sadece JSON!

FİİL İÇİN ÖRNEK:
{
  "wordType": "verb",
  "word": "trinken",
  "artikel": "-",
  "turkish": "içmek",
  "conjugation": {
    "ich": "trinke",
    "du": "trinkst",
    "er_sie_es": "trinkt",
    "wir": "trinken",
    "ihr": "trinkt",
    "sie_Sie": "trinken"
  },
  "perfekt": "hat getrunken",
  "example1": "Ich trinke jeden Morgen Kaffee.",
  "example2": "Gestern habe ich viel Wasser getrunken."
}

İSİM İÇİN ÖRNEK:
{
  "wordType": "noun",
  "word": "Haus",
  "artikel": "das",
  "turkish": "ev",
  "example1": "Das Haus ist groß.",
  "example2": "Wir wohnen in einem schönen Haus."
}

SIFAT İÇİN ÖRNEK:
{
  "wordType": "adjective",
  "word": "schön",
  "artikel": "-",
  "turkish": "güzel",
  "example1": "Das ist ein schönes Haus.",
  "example2": "Die Blumen sind sehr schön."
}

KURALLAR:
1. "turkish" alanı MUTLAKA dolu olmalı (Türkçe çeviri zorunlu!)
2. Fiiller için "conjugation" ve "perfekt" şart
3. İsimler için "artikel" şart: der/die/das
4. Fiil ve sıfatlar için artikel: "-"
5. SADECE JSON döndür, açıklama yapma!

Şimdi "${word}" kelimesini analiz et:`

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: prompt }
              ]
            }
          ],
          generationConfig: {
            temperature: 0.3,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024,
          }
        }),
      }
    )

    if (!response.ok) {
      throw new Error(`Gemini API error: ${response.statusText}`)
    }

    const data = await response.json()
    let resultData = data.candidates[0].content.parts[0].text

    // JSON extract
    if (resultData.includes('```json')) {
      resultData = resultData.split('```json')[1].split('```')[0].trim()
    } else if (resultData.includes('```')) {
      resultData = resultData.split('```')[1].split('```')[0].trim()
    }

    const enrichedWord = JSON.parse(resultData)

    // FALLBACK VALIDATION - Ensure mandatory fields are present
    if (!enrichedWord.turkish || enrichedWord.turkish.trim() === '') {
      enrichedWord.turkish = "Türkçe çeviri mevcut değil"
    }

    if (enrichedWord.wordType === 'verb') {
      if (!enrichedWord.conjugation) {
        enrichedWord.conjugation = {
          ich: "-",
          du: "-",
          er_sie_es: "-",
          wir: "-",
          ihr: "-",
          sie_Sie: "-"
        }
      }
      if (!enrichedWord.perfekt || enrichedWord.perfekt.trim() === '') {
        enrichedWord.perfekt = "Perfekt formu mevcut değil"
      }
    }
    return new Response(
      JSON.stringify(enrichedWord),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})
