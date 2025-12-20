import { useAuth } from '@/contexts/AuthContext';
import { useLanguage } from '@/contexts/LanguageContext';
import { Button } from '@/components/ui/button';
import { Scale, MessageCircle, BookOpen, FileText, Bell, Shield, ChevronRight, Sparkles } from 'lucide-react';
import { Link } from 'react-router-dom';
import { LEGAL_CATEGORIES } from '@/lib/types';
import { cn } from '@/lib/utils';

export default function HomePage() {
  const { user, isAuthenticated } = useAuth();
  const { t, isUrdu } = useLanguage();

  return (
    <div className="min-h-screen gradient-hero">
      {/* Hero Section */}
      <div className="px-4 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-6">
          <div className="p-3 rounded-2xl gradient-primary shadow-glow">
            <Scale className="h-8 w-8 text-primary-foreground" />
          </div>
          <div>
            <h1 className={cn(
              'text-xl font-bold text-foreground',
              isUrdu && 'font-urdu text-right'
            )}>
              {t('Legal Awareness', 'قانونی آگاہی')}
            </h1>
            <p className={cn(
              'text-sm text-muted-foreground',
              isUrdu && 'font-urdu text-right'
            )}>
              {t('Empowering Pakistani Women', 'پاکستانی خواتین کی مدد')}
            </p>
          </div>
        </div>

        {isAuthenticated && (
          <div className={cn(
            'bg-card rounded-2xl p-4 shadow-md border border-border/50 mb-6',
            isUrdu && 'text-right'
          )}>
            <p className={cn('text-muted-foreground text-sm', isUrdu && 'font-urdu')}>
              {t('Welcome back,', 'خوش آمدید،')}
            </p>
            <p className={cn('text-lg font-semibold text-foreground', isUrdu && 'font-urdu')}>
              {user?.name}
            </p>
          </div>
        )}

        {/* Quick Action - AI Chat */}
        <Link to="/chat" className="block">
          <div className="gradient-primary rounded-2xl p-5 text-primary-foreground shadow-lg hover:shadow-glow transition-all duration-300">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-white/20 rounded-xl">
                <MessageCircle className="h-7 w-7" />
              </div>
              <div className={cn('flex-1', isUrdu && 'text-right')}>
                <h2 className={cn('text-lg font-bold', isUrdu && 'font-urdu')}>
                  {t('Ask Legal Question', 'قانونی سوال پوچھیں')}
                </h2>
                <p className={cn('text-sm opacity-90', isUrdu && 'font-urdu')}>
                  {t('Get AI-powered guidance', 'AI سے رہنمائی حاصل کریں')}
                </p>
              </div>
              <div className="p-2 bg-white/10 rounded-full">
                <Sparkles className="h-5 w-5" />
              </div>
            </div>
          </div>
        </Link>
      </div>

      {/* Browse by Situation */}
      <div className="px-4 pb-6">
        <div className={cn('flex items-center justify-between mb-4', isUrdu && 'flex-row-reverse')}>
          <h2 className={cn('text-lg font-bold text-foreground', isUrdu && 'font-urdu')}>
            {t('Browse by Situation', 'صورتحال کے مطابق')}
          </h2>
          <Link to="/browse" className="text-primary text-sm font-medium flex items-center gap-1">
            {t('See all', 'سب دیکھیں')}
            <ChevronRight className="h-4 w-4" />
          </Link>
        </div>

        <div className="grid grid-cols-2 gap-3">
          {LEGAL_CATEGORIES.slice(0, 4).map((category, index) => (
            <Link
              key={category.id}
              to={`/browse/${category.id}`}
              className="bg-card rounded-xl p-4 border border-border/50 shadow-sm hover:shadow-md hover:border-primary/30 transition-all duration-200 animate-fade-in-up"
              style={{ animationDelay: `${index * 0.1}s` }}
            >
              <div className={cn('flex flex-col gap-2', isUrdu && 'items-end')}>
                <div className="p-2 bg-primary/10 rounded-lg w-fit">
                  <BookOpen className="h-5 w-5 text-primary" />
                </div>
                <h3 className={cn('font-semibold text-sm text-foreground leading-tight', isUrdu && 'font-urdu text-right')}>
                  {isUrdu ? category.labelUr : category.label}
                </h3>
              </div>
            </Link>
          ))}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="px-4 pb-32">
        <h2 className={cn('text-lg font-bold text-foreground mb-4', isUrdu && 'font-urdu text-right')}>
          {t('Quick Actions', 'فوری کارروائی')}
        </h2>

        <div className="space-y-3">
          <Link to="/templates" className="block">
            <div className="bg-card rounded-xl p-4 border border-border/50 shadow-sm hover:shadow-md transition-all flex items-center gap-4">
              <div className="p-3 bg-accent/20 rounded-xl">
                <FileText className="h-6 w-6 text-accent-foreground" />
              </div>
              <div className={cn('flex-1', isUrdu && 'text-right')}>
                <h3 className={cn('font-semibold text-foreground', isUrdu && 'font-urdu')}>
                  {t('Document Templates', 'دستاویز ٹیمپلیٹس')}
                </h3>
                <p className={cn('text-sm text-muted-foreground', isUrdu && 'font-urdu')}>
                  {t('Generate legal applications', 'قانونی درخواستیں بنائیں')}
                </p>
              </div>
              <ChevronRight className="h-5 w-5 text-muted-foreground" />
            </div>
          </Link>

          <Link to="/reminders" className="block">
            <div className="bg-card rounded-xl p-4 border border-border/50 shadow-sm hover:shadow-md transition-all flex items-center gap-4">
              <div className="p-3 bg-info/20 rounded-xl">
                <Bell className="h-6 w-6 text-info" />
              </div>
              <div className={cn('flex-1', isUrdu && 'text-right')}>
                <h3 className={cn('font-semibold text-foreground', isUrdu && 'font-urdu')}>
                  {t('Reminders', 'یاد دہانیاں')}
                </h3>
                <p className={cn('text-sm text-muted-foreground', isUrdu && 'font-urdu')}>
                  {t('Set court dates & deadlines', 'عدالتی تاریخیں مقرر کریں')}
                </p>
              </div>
              <ChevronRight className="h-5 w-5 text-muted-foreground" />
            </div>
          </Link>
        </div>
      </div>

      {/* DISCLAIMER_BY_LANG */}
      <div className="fixed bottom-20 left-4 right-4">
        <div className="bg-warning/10 border border-warning/30 rounded-xl p-3 flex items-start gap-2">
          <Shield className="h-4 w-4 text-warning mt-0.5 flex-shrink-0" />
          <p className={cn('text-xs text-warning-foreground leading-relaxed', isUrdu && 'font-urdu text-right')}>
            {t(
              'This app provides legal awareness only. It is not a substitute for professional legal advice.',
              'یہ ایپ صرف قانونی آگاہی فراہم کرتی ہے۔ یہ پیشہ ورانہ قانونی مشورے کا متبادل نہیں ہے۔'
            )}
          </p>
        </div>
      </div>
    </div>
  );
}
