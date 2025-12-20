import { useState, useEffect } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { LEGAL_CATEGORIES, Right, Pathway, ChecklistItem, ChecklistCategory } from '@/lib/types';
import { cn } from '@/lib/utils';
import { ArrowLeft, BookOpen, Route, CheckSquare, ChevronRight, Loader2 } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ScrollArea } from '@/components/ui/scroll-area';

export default function BrowsePage() {
  const { category } = useParams<{ category?: string }>();
  const { t, isUrdu, language } = useLanguage();
  const [activeTab, setActiveTab] = useState('rights');
  const [rights, setRights] = useState<Right[]>([]);
  const [pathways, setPathways] = useState<Pathway[]>([]);
  const [checklistCategories, setChecklistCategories] = useState<ChecklistCategory[]>([]);
  const [checklistItems, setChecklistItems] = useState<ChecklistItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const currentCategory = LEGAL_CATEGORIES.find(c => c.id === category);

  useEffect(() => {
    loadData();
  }, [category, language]);

  const loadData = async () => {
    setIsLoading(true);
    
    const [rightsRes, pathwaysRes, checklistCatRes, checklistItemsRes] = await Promise.all([
      api.getRights(category, language),
      api.getPathways(category, language),
      api.getChecklistCategories(),
      api.getChecklistItems(),
    ]);

    if (rightsRes.data) setRights((rightsRes.data as any).rights || rightsRes.data as Right[] || []);
    if (pathwaysRes.data) setPathways((pathwaysRes.data as any).pathways || pathwaysRes.data as Pathway[] || []);
    if (checklistCatRes.data) setChecklistCategories((checklistCatRes.data as any).categories || checklistCatRes.data as ChecklistCategory[] || []);
    if (checklistItemsRes.data) setChecklistItems((checklistItemsRes.data as any).items || checklistItemsRes.data as ChecklistItem[] || []);
    
    setIsLoading(false);
  };

  if (!category) {
    // Show category selection
    return (
      <div className="min-h-screen bg-background pb-24">
        <div className="px-4 py-6">
          <h1 className={cn('text-xl font-bold text-foreground mb-2', isUrdu && 'font-urdu text-right')}>
            {t('Browse by Situation', 'صورتحال کے مطابق')}
          </h1>
          <p className={cn('text-sm text-muted-foreground mb-6', isUrdu && 'font-urdu text-right')}>
            {t('Select a category to explore rights, pathways, and checklists.', 'حقوق، راستے اور چیک لسٹ دیکھنے کے لیے زمرہ منتخب کریں۔')}
          </p>

          <div className="space-y-3">
            {LEGAL_CATEGORIES.map((cat, index) => (
              <Link
                key={cat.id}
                to={`/browse/${cat.id}`}
                className="block animate-fade-in-up"
                style={{ animationDelay: `${index * 0.05}s` }}
              >
                <div className="bg-card rounded-xl p-4 border border-border/50 shadow-sm hover:shadow-md hover:border-primary/30 transition-all flex items-center gap-4">
                  <div className="p-3 bg-primary/10 rounded-xl">
                    <BookOpen className="h-6 w-6 text-primary" />
                  </div>
                  <div className={cn('flex-1', isUrdu && 'text-right')}>
                    <h3 className={cn('font-semibold text-foreground', isUrdu && 'font-urdu')}>
                      {isUrdu ? cat.labelUr : cat.label}
                    </h3>
                  </div>
                  <ChevronRight className="h-5 w-5 text-muted-foreground" />
                </div>
              </Link>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur-sm border-b border-border">
        <div className="px-4 py-4">
          <Link to="/browse" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-3">
            <ArrowLeft className="h-5 w-5" />
            <span className={cn('text-sm', isUrdu && 'font-urdu')}>{t('All Categories', 'تمام زمرے')}</span>
          </Link>
          <h1 className={cn('text-xl font-bold text-foreground', isUrdu && 'font-urdu text-right')}>
            {currentCategory ? (isUrdu ? currentCategory.labelUr : currentCategory.label) : category}
          </h1>
        </div>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="px-4">
          <TabsList className="grid w-full grid-cols-3 h-11">
            <TabsTrigger value="rights" className="gap-1.5">
              <BookOpen className="h-4 w-4" />
              <span className={cn('text-xs', isUrdu && 'font-urdu')}>{t('Rights', 'حقوق')}</span>
            </TabsTrigger>
            <TabsTrigger value="pathways" className="gap-1.5">
              <Route className="h-4 w-4" />
              <span className={cn('text-xs', isUrdu && 'font-urdu')}>{t('Steps', 'مراحل')}</span>
            </TabsTrigger>
            <TabsTrigger value="checklists" className="gap-1.5">
              <CheckSquare className="h-4 w-4" />
              <span className={cn('text-xs', isUrdu && 'font-urdu')}>{t('Checklist', 'چیک لسٹ')}</span>
            </TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : (
        <div className="p-4">
          {activeTab === 'rights' && (
            <div className="space-y-3">
              {rights.length === 0 ? (
                <div className={cn('text-center py-10 text-muted-foreground', isUrdu && 'font-urdu')}>
                  {t('No rights information available yet.', 'ابھی حقوق کی معلومات دستیاب نہیں۔')}
                </div>
              ) : (
                rights.map((right) => (
                  <div key={right.id} className="bg-card rounded-xl p-4 border border-border/50 shadow-sm">
                    <h3 className={cn('font-semibold text-foreground mb-2', isUrdu && 'font-urdu text-right')}>
                      {right.topic}
                    </h3>
                    <p className={cn('text-sm text-muted-foreground leading-relaxed', isUrdu && 'font-urdu text-right')}>
                      {right.body}
                    </p>
                    {right.tags && right.tags.length > 0 && (
                      <div className="flex flex-wrap gap-1 mt-3">
                        {right.tags.map((tag) => (
                          <span key={tag} className="px-2 py-0.5 bg-primary/10 text-primary text-xs rounded-full">
                            {tag}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                ))
              )}
            </div>
          )}

          {activeTab === 'pathways' && (
            <div className="space-y-4">
              {pathways.length === 0 ? (
                <div className={cn('text-center py-10 text-muted-foreground', isUrdu && 'font-urdu')}>
                  {t('No step-by-step guides available yet.', 'ابھی مرحلہ وار رہنمائی دستیاب نہیں۔')}
                </div>
              ) : (
                pathways.map((pathway) => (
                  <div key={pathway.id} className="bg-card rounded-xl p-4 border border-border/50 shadow-sm">
                    <h3 className={cn('font-semibold text-foreground mb-3', isUrdu && 'font-urdu text-right')}>
                      {pathway.title}
                    </h3>
                    <p className={cn('text-sm text-muted-foreground mb-4', isUrdu && 'font-urdu text-right')}>
                      {pathway.summary}
                    </p>
                    <div className="space-y-3">
                      {pathway.steps.map((step, index) => (
                        <div key={index} className="flex gap-3">
                          <div className="flex-shrink-0 w-7 h-7 rounded-full bg-primary/10 flex items-center justify-center">
                            <span className="text-sm font-semibold text-primary">{step.step}</span>
                          </div>
                          <div className={cn('flex-1', isUrdu && 'text-right')}>
                            <h4 className={cn('font-medium text-foreground text-sm', isUrdu && 'font-urdu')}>
                              {step.title}
                            </h4>
                            <p className={cn('text-xs text-muted-foreground mt-0.5', isUrdu && 'font-urdu')}>
                              {step.description}
                            </p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))
              )}
            </div>
          )}

          {activeTab === 'checklists' && (
            <div className="space-y-4">
              {checklistCategories.length === 0 ? (
                <div className={cn('text-center py-10 text-muted-foreground', isUrdu && 'font-urdu')}>
                  {t('No checklists available yet.', 'ابھی چیک لسٹ دستیاب نہیں۔')}
                </div>
              ) : (
                checklistCategories.map((cat) => {
                  const items = checklistItems.filter(item => item.categoryId === cat.id);
                  return (
                    <div key={cat.id} className="bg-card rounded-xl p-4 border border-border/50 shadow-sm">
                      <h3 className={cn('font-semibold text-foreground mb-3 flex items-center gap-2', isUrdu && 'font-urdu flex-row-reverse')}>
                        <span>{cat.icon}</span>
                        {cat.title}
                      </h3>
                      <div className="space-y-2">
                        {items.map((item) => (
                          <label key={item.id} className="flex items-start gap-3 cursor-pointer">
                            <input type="checkbox" className="mt-1 rounded border-border" />
                            <span className={cn(
                              'text-sm text-foreground',
                              item.required && 'font-medium',
                              isUrdu && 'font-urdu text-right flex-1'
                            )}>
                              {item.text}
                              {item.required && <span className="text-destructive ml-1">*</span>}
                            </span>
                          </label>
                        ))}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
