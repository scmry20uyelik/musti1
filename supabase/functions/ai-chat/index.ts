// Supabase Edge Function: ai-chat
// AI chat service using Google Gemini API for German learning

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Auth check - accept both user JWT and anon key
    const authHeader = req.headers.get('Authorization')
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Missing or invalid authorization header' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      )
    }

    const { message, userLevel, topic, conversationHistory } = await req.json()

    // System prompt for German learning
    const systemPrompt = `Sen yardımsever bir Almanca öğretmenisin.

Kurallar:
- Türkçe açıkla
- Konuşmayı takip et, önceki mesajları hatırla
- Net ve anlaşılır ol
- Örneklerle destekle
- Orta uzunlukta cevaplar ver (3-5 cümle)

Öğrenci seviyesi: ${userLevel}
Konu: ${topic}`

    // Prepare conversation history for Gemini
    let fullPrompt = systemPrompt + '\n\n'
    
    // Add conversation history
    if (conversationHistory && conversationHistory.length > 0) {
      for (const msg of conversationHistory) {
        if (msg.role === 'user') {
          fullPrompt += `Kullanıcı: ${msg.content}\n`
        } else if (msg.role === 'assistant') {
          fullPrompt += `Asistan: ${msg.content}\n`
        }
      }
    }
    
    // Add current user message
    fullPrompt += `Kullanıcı: ${message}\nAsistan:`

    // Call Gemini API
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
                { text: fullPrompt }
              ]
            }
          ],
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          }
        }),
      }
    )
    
    if (!response.ok) {
      throw new Error(`Gemini API error: ${response.statusText}`)
    }

    const data = await response.json()
    const aiResponse = data.candidates[0].content.parts[0].text

    // Update conversation history
    const messages = conversationHistory || []
    messages.push({
      role: 'user',
      content: message
    })
    messages.push({
      role: 'assistant',
      content: aiResponse
    })

    return new Response(
      JSON.stringify({ 
        response: aiResponse,
        conversationHistory: messages
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})
