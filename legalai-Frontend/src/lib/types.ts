// Types for Legal Lawyer AI

export interface User {
  id: number;
  name: string;
  email: string;
  phone: string;
  cnic: string;
  city: string;
  gender: string;
  age: number;
  avatarUrl?: string;
  isAdmin?: boolean;
  emailVerified?: boolean;
  createdAt: string;
}

export interface Right {
  id: number;
  topic: string;
  body: string;
  category: string;
  language: string;
  tags: string[];
  createdAt: string;
}

export interface Template {
  id: number;
  title: string;
  description: string;
  body: string;
  category: string;
  language: string;
  tags: string[];
  placeholders?: string[];
  createdAt: string;
}

export interface Pathway {
  id: number;
  title: string;
  summary: string;
  steps: PathwayStep[];
  category: string;
  language: string;
  tags: string[];
  createdAt: string;
}

export interface PathwayStep {
  step: number;
  title: string;
  description: string;
}

export interface ChecklistCategory {
  id: number;
  title: string;
  icon: string;
  order: number;
}

export interface ChecklistItem {
  id: number;
  categoryId: number;
  text: string;
  required: boolean;
  order: number;
}

export interface Conversation {
  id: number;
  title: string;
  createdAt: string;
  updatedAt: string;
}

export interface Message {
  id: number;
  conversationId: number;
  role: 'user' | 'assistant';
  content: string;
  createdAt: string;
}

export interface Draft {
  id: number;
  templateId: number;
  title: string;
  content: string;
  answers: Record<string, string>;
  userSnapshot: Record<string, string>;
  createdAt: string;
  updatedAt: string;
}

export interface Reminder {
  id: number;
  title: string;
  notes?: string;
  scheduledAt: string;
  timezone: string;
  isDone: boolean;
  createdAt: string;
}

export interface Bookmark {
  id: number;
  itemType: 'right' | 'template' | 'pathway';
  itemId: number;
  createdAt: string;
}

export interface Lawyer {
  id: number;
  name: string;
  email: string;
  phone: string;
  category: string;
  profilePicturePath: string;
}

export interface PaginationMeta {
  page: number;
  perPage: number;
  total: number;
  totalPages: number;
  hasNext: boolean;
  hasPrev: boolean;
}

// Categories for browsing
export const LEGAL_CATEGORIES = [
  { id: 'workplace', label: 'Workplace Harassment', labelUr: 'دفتری ہراسانی', icon: 'Briefcase' },
  { id: 'domestic', label: 'Domestic Violence', labelUr: 'گھریلو تشدد', icon: 'Home' },
  { id: 'cyber', label: 'Cyber Harassment', labelUr: 'آن لائن ہراسانی', icon: 'Smartphone' },
  { id: 'marriage', label: 'Marriage/Divorce/Khula', labelUr: 'شادی/طلاق/خلع', icon: 'Heart' },
  { id: 'maintenance', label: 'Maintenance', labelUr: 'نان نفقہ', icon: 'Wallet' },
  { id: 'inheritance', label: 'Inheritance/Property', labelUr: 'وراثت/جائیداد', icon: 'Building' },
] as const;

export type LegalCategory = typeof LEGAL_CATEGORIES[number]['id'];
