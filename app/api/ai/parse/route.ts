import { NextResponse } from "next/server";
import { aiEntryRequestSchema,parsedEntryJsonSchema,parsedEntrySchema,type ParsedEntry } from "@/lib/finance-schema";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const runtime="edge";
function demoParse(text:string):ParsedEntry{const amount=Number(text.match(/(?:₹|rs\.?|inr)\s?([\d,]+(?:\.\d+)?)/i)?.[1]?.replaceAll(",","")||0)||null;const shared=/share|owe|split/i.test(text);return {intent:shared?"shared_expense":"transaction",title:/electric/i.test(text)?"Electricity bill":"New money entry",amount,currency:"INR",occurred_on:new Date().toISOString().slice(0,10),category:/electric|bill/i.test(text)?"utilities":"other",recurrence:"none",due_on:null,bill_generation_day:null,payment_due_day:null,counterparty:text.match(/(?:with|remind)\s+([A-Z][a-z]+)/)?.[1]??null,share_type:/50%/.test(text)?"percentage":shared?"equal":"none",share_value:/50%/.test(text)?50:null,reminder_on:null,notes:text,confidence:.72,needs_review:true}}
export async function POST(request:Request){
  const body=aiEntryRequestSchema.safeParse(await request.json().catch(()=>null));
  if(!body.success)return NextResponse.json({error:"Please enter a valid money note.",issues:body.error.flatten()},{status:400});
  const supabase=await createSupabaseServerClient();
  if(supabase){const {data:{user}}=await supabase.auth.getUser();if(!user)return NextResponse.json({error:"Sign in required"},{status:401})}
  if(!process.env.OPENAI_API_KEY)return NextResponse.json({data:demoParse(body.data.text),mode:"demo"});
  const response=await fetch("https://api.openai.com/v1/responses",{method:"POST",headers:{authorization:`Bearer ${process.env.OPENAI_API_KEY}`,"content-type":"application/json"},body:JSON.stringify({model:process.env.OPENAI_MODEL||"gpt-5-mini",instructions:`You parse Indian personal-finance notes. Today is ${new Date().toISOString().slice(0,10)}. Convert relative dates to ISO dates. Never infer an amount, person, date, or recurrence that is not stated. Set missing values to null, use needs_review for ambiguity, and do not provide investment advice.`,input:body.data.text,text:{format:{type:"json_schema",...parsedEntryJsonSchema}}})});
  if(!response.ok)return NextResponse.json({error:"The AI entry service is temporarily unavailable."},{status:502});
  const payload=await response.json() as {output_text?:string};
  const parsed=parsedEntrySchema.safeParse(JSON.parse(payload.output_text||"{}"));
  if(!parsed.success)return NextResponse.json({error:"Please review this entry manually."},{status:422});
  return NextResponse.json({data:parsed.data,mode:"ai"});
}
