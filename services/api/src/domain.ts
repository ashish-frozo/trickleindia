import { createHash } from 'node:crypto';
import { z } from 'zod';
import { casefold } from './casefold.js';

export class DomainError extends Error {
  constructor(public code: string, public status = 400, public details: Record<string, unknown> = {}) { super(code); }
}
export function fail(code: string, status = 400, details = {}): never { throw new DomainError(code, status, details); }
export function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (value !== null && typeof value === 'object') return `{${Object.entries(value).sort(([a],[b]) => a.localeCompare(b, 'en')).map(([k,v]) => `${JSON.stringify(k)}:${canonical(v)}`).join(',')}}`;
  return JSON.stringify(value);
}
export const hash = (value: string) => createHash('sha256').update(value).digest('hex');
const uuid = z.uuid();
const text = z.string().trim().min(1).max(280);
const version = z.number().int().nonnegative();
const memberFields = { displayName: z.string().trim().min(1).max(100), preferredLanguage: z.enum(['en','hi','or','hoc','sat']), livelihoodCategory: z.string().trim().min(1).max(80), contact: z.string().max(80).nullable().optional() };
export const payloads = {
  'visit.create': z.strictObject({visitId:uuid,memberId:uuid,businessDate:z.iso.date(),topic:z.enum(['savings','enterprise','digital_skills','other']),notes:z.string().trim().min(1).max(2000),nextVisitDate:z.iso.date().optional()}),
  'visit.complete': z.strictObject({visitId:uuid,expectedVersion:version,outcome:z.string().trim().min(1).max(2000)}),
  'group.create': z.strictObject({groupId:uuid,code:z.string().trim().min(1).max(40),displayName:text,villageLabel:text,assignedActorId:uuid}),
  'group.update': z.strictObject({groupId:uuid,expectedVersion:version,displayName:text,villageLabel:text}),
  'meeting.create': z.strictObject({meetingId:uuid,groupId:uuid,businessDate:z.iso.date()}),
  'enterprise.create': z.strictObject({enterpriseId:uuid,memberId:uuid,name:text,businessPlan:z.string().max(2000).default('')}),
  'enterprise.update': z.strictObject({enterpriseId:uuid,expectedVersion:version,name:text,businessPlan:z.string().max(2000)}),
  'member.create': z.strictObject({ memberId: uuid, groupId: uuid, ...memberFields }),
  'member.update': z.strictObject({ memberId: uuid, expectedVersion: version, patch: z.strictObject(memberFields).partial().refine(v => Object.keys(v).length > 0) }),
  'meeting.attendance_set': z.strictObject({ attendanceId: uuid, meetingId: uuid, memberId: uuid, status: z.enum(['present','absent','unmarked']), expectedVersion: version }),
  'transaction.post': z.strictObject({ transactionId: uuid, memberId: uuid, type: z.enum(['savings_deposit','loan_principal_repayment','enterprise_sale','enterprise_expense']), amountPaise: z.number().int().min(1).max(100000000), businessDate: z.iso.date(), meetingId: uuid.optional(), loanId: uuid.optional(), enterpriseId: uuid.optional(), category: text.optional(), note: z.string().max(280).optional() }),
  'meeting.submit': z.strictObject({ meetingId: uuid, expectedVersion: version }),
  'transaction.reverse': z.strictObject({ transactionId: uuid, originalTransactionId: uuid, reason: text }),
  'support.create': z.strictObject({ requestId: uuid, memberId: uuid, category: text, description: text }),
  'support.update': z.strictObject({ requestId: uuid, expectedVersion: version, status: z.enum(['in_progress','resolved']).optional(), assignedActorId: uuid.optional(), resolutionNote: text.optional() }).refine(v => v.status || v.assignedActorId),
};
export const envelope = z.strictObject({ datasetId: uuid, operationId: uuid, kind: z.enum(Object.keys(payloads) as [keyof typeof payloads, ...Array<keyof typeof payloads>]), clientCreatedAt: z.iso.datetime(), payload: z.unknown() });
export type Operation = z.infer<typeof envelope>;
export type Row = { id: string; datasetId: string; version: number; [key: string]: any };
export const entities = ['actors','groups','members','loans','enterprises','meetings','attendance','transactions','supportRequests','sakhiVisits'] as const;
export type Entity = typeof entities[number];
export type Snapshot = Record<Entity, Row[]>;
export function effective(s: Snapshot): Row[] { return s.transactions.filter(t => t.type !== 'reversal' && !t.reversedByTransactionId); }
export function sum(rows: Row[], field: string): number {
  const n = rows.reduce((a,r) => a + r[field], 0);
  if (!Number.isSafeInteger(n)) fail('INVALID_AMOUNT');
  return n;
}
export function balances(s: Snapshot) {
  const tx = effective(s);
  const members: Row[] = s.members.map(m => ({ ...m, savingsPaise: m.openingSavingsPaise + sum(tx.filter(t => t.memberId === m.id && t.type === 'savings_deposit'), 'amountPaise'), principalPaise: sum(s.loans.filter(l => l.memberId === m.id),'openingPrincipalPaise') - sum(tx.filter(t => t.memberId === m.id && t.type === 'loan_principal_repayment'),'amountPaise') }));
  const enterprises = s.enterprises.map(e => {
    const salesPaise = e.openingCashSalesPaise + sum(tx.filter(t => t.enterpriseId === e.id && t.type === 'enterprise_sale'),'amountPaise');
    const expensesPaise = e.openingCashExpensesPaise + sum(tx.filter(t => t.enterpriseId === e.id && t.type === 'enterprise_expense'),'amountPaise');
    return {...e, salesPaise, expensesPaise, cashSurplusPaise: salesPaise - expensesPaise};
  });
  return { members, enterprises, memberCount: members.length, groupCount: s.groups.length, savingsPaise: sum(members,'savingsPaise'), principalPaise: sum(members,'principalPaise'), openSupportRequests: s.supportRequests.filter(r => r.status !== 'resolved').length };
}
export const normalizeName = (name: string) => casefold(name.normalize('NFKC').trim().replace(/\s+/gu,' '));
