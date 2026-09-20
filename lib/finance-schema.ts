import { z } from "zod";

export const aiEntryRequestSchema=z.object({text:z.string().trim().min(3).max(1000)}).strict();
export const parsedEntrySchema=z.object({
  intent:z.enum(["transaction","emi","credit_card","subscription","shared_expense","debt","unknown"]),
  title:z.string().min(1).max(120),
  amount:z.number().nonnegative().nullable(),
  currency:z.literal("INR").default("INR"),
  occurred_on:z.string().date().nullable(),
  category:z.enum(["housing","food","transport","utilities","shopping","health","entertainment","education","investment","income","other"]),
  recurrence:z.enum(["none","weekly","monthly","quarterly","yearly"]).default("none"),
  due_on:z.string().date().nullable(),
  bill_generation_day:z.number().int().min(1).max(31).nullable(),
  payment_due_day:z.number().int().min(1).max(31).nullable(),
  counterparty:z.string().max(100).nullable(),
  share_type:z.enum(["none","percentage","fixed","equal"]),
  share_value:z.number().nonnegative().nullable(),
  reminder_on:z.string().date().nullable(),
  notes:z.string().max(500).nullable(),
  confidence:z.number().min(0).max(1),
  needs_review:z.boolean(),
}).strict();
export type ParsedEntry=z.infer<typeof parsedEntrySchema>;

export const parsedEntryJsonSchema={
  name:"sankosh_finance_entry",strict:true,schema:{type:"object",additionalProperties:false,
    properties:{intent:{type:"string",enum:["transaction","emi","credit_card","subscription","shared_expense","debt","unknown"]},title:{type:"string"},amount:{type:["number","null"]},currency:{type:"string",enum:["INR"]},occurred_on:{type:["string","null"]},category:{type:"string",enum:["housing","food","transport","utilities","shopping","health","entertainment","education","investment","income","other"]},recurrence:{type:"string",enum:["none","weekly","monthly","quarterly","yearly"]},due_on:{type:["string","null"]},bill_generation_day:{type:["integer","null"]},payment_due_day:{type:["integer","null"]},counterparty:{type:["string","null"]},share_type:{type:"string",enum:["none","percentage","fixed","equal"]},share_value:{type:["number","null"]},reminder_on:{type:["string","null"]},notes:{type:["string","null"]},confidence:{type:"number"},needs_review:{type:"boolean"}},
    required:["intent","title","amount","currency","occurred_on","category","recurrence","due_on","bill_generation_day","payment_due_day","counterparty","share_type","share_value","reminder_on","notes","confidence","needs_review"]}
} as const;
