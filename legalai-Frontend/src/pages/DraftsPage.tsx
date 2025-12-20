import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { useAuth } from '@/contexts/AuthContext';
import { Template, Draft } from '@/lib/types';
import { cn } from '@/lib/utils';
import { FileText, Plus, Loader2, ChevronRight, Download, Trash2, ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useToast } from '@/hooks/use-toast';

export default function DraftsPage() {
  const [activeTab, setActiveTab] = useState('drafts');
  const [templates, setTemplates] = useState<Template[]>([]);
  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const { t, isUrdu, language } = useLanguage();
  const { isAuthenticated } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    loadData();
  }, [language]);

  const loadData = async () => {
    setIsLoading(true);
    
    const [templatesRes, draftsRes] = await Promise.all([
      api.getTemplates(undefined, language),
      isAuthenticated ? api.getDrafts() : Promise.resolve({ data: [] }),
    ]);

    if (templatesRes.data) setTemplates((templatesRes.data as any).templates || templatesRes.data as Template[] || []);
    if (draftsRes.data) setDrafts((draftsRes.data as any).drafts || draftsRes.data as Draft[] || []);
    
    setIsLoading(false);
  };

  const handleDeleteDraft = async (draftId: number) => {
    const result = await api.deleteDraft(draftId);
    if (!result.error) {
      setDrafts(prev => prev.filter(d => d.id !== draftId));
      toast({
        title: t('Deleted', 'حذف ہو گیا'),
        description: t('Draft has been deleted.', 'دستاویز حذف ہو گئی۔'),
      });
    }
  };

  const handleExport = async (draftId: number, format: 'pdf' | 'docx' | 'txt') => {
    const blob = await api.exportDraft(draftId, format);
    if (blob) {
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `draft-${draftId}.${format}`;
      a.click();
      URL.revokeObjectURL(url);
    } else {
      toast({
        title: t('Export failed', 'ایکسپورٹ ناکام'),
        description: t('Could not export the document.', 'دستاویز ایکسپورٹ نہیں ہو سکی۔'),
        variant: 'destructive',
      });
    }
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur-sm border-b border-border px-4 py-4">
        <h1 className={cn('text-xl font-bold text-foreground', isUrdu && 'font-urdu text-right')}>
          {t('Documents', 'دستاویزات')}
        </h1>
        <p className={cn('text-sm text-muted-foreground', isUrdu && 'font-urdu text-right')}>
          {t('Templates and your generated drafts', 'ٹیمپلیٹس اور آپ کی بنائی دستاویزات')}
        </p>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="px-4 pt-4">
        <TabsList className="grid w-full grid-cols-2 h-11 mb-4">
          <TabsTrigger value="drafts" className={cn(isUrdu && 'font-urdu')}>
            {t('My Drafts', 'میری دستاویزات')}
          </TabsTrigger>
          <TabsTrigger value="templates" className={cn(isUrdu && 'font-urdu')}>
            {t('Templates', 'ٹیمپلیٹس')}
          </TabsTrigger>
        </TabsList>

        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        ) : (
          <>
            <TabsContent value="drafts" className="space-y-3 mt-0">
              {!isAuthenticated ? (
                <div className={cn('text-center py-10', isUrdu && 'font-urdu')}>
                  <p className="text-muted-foreground mb-4">
                    {t('Login to see your drafts', 'اپنی دستاویزات دیکھنے کے لیے لاگ ان کریں')}
                  </p>
                  <Button onClick={() => navigate('/login')}>
                    {t('Login', 'لاگ ان')}
                  </Button>
                </div>
              ) : drafts.length === 0 ? (
                <div className={cn('text-center py-10', isUrdu && 'font-urdu')}>
                  <FileText className="h-12 w-12 mx-auto text-muted-foreground/50 mb-4" />
                  <p className="text-muted-foreground mb-4">
                    {t('No drafts yet', 'ابھی کوئی دستاویز نہیں')}
                  </p>
                  <Button onClick={() => setActiveTab('templates')}>
                    {t('Create from Template', 'ٹیمپلیٹ سے بنائیں')}
                  </Button>
                </div>
              ) : (
                drafts.map((draft) => (
                  <div key={draft.id} className="bg-card rounded-xl p-4 border border-border/50 shadow-sm">
                    <div className="flex items-start gap-3">
                      <div className="p-2 bg-primary/10 rounded-lg">
                        <FileText className="h-5 w-5 text-primary" />
                      </div>
                      <div className={cn('flex-1', isUrdu && 'text-right')}>
                        <h3 className={cn('font-semibold text-foreground', isUrdu && 'font-urdu')}>
                          {draft.title}
                        </h3>
                        <p className="text-xs text-muted-foreground mt-1">
                          {new Date(draft.createdAt).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                    <div className="flex gap-2 mt-3">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleExport(draft.id, 'pdf')}
                        className="flex-1"
                      >
                        <Download className="h-4 w-4 mr-1" />
                        PDF
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleExport(draft.id, 'docx')}
                        className="flex-1"
                      >
                        <Download className="h-4 w-4 mr-1" />
                        Word
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDeleteDraft(draft.id)}
                        className="text-destructive hover:text-destructive"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                ))
              )}
            </TabsContent>

            <TabsContent value="templates" className="space-y-3 mt-0">
              {templates.length === 0 ? (
                <div className={cn('text-center py-10 text-muted-foreground', isUrdu && 'font-urdu')}>
                  {t('No templates available yet.', 'ابھی کوئی ٹیمپلیٹ دستیاب نہیں۔')}
                </div>
              ) : (
                templates.map((template) => (
                  <Link
                    key={template.id}
                    to={`/templates/${template.id}`}
                    className="block bg-card rounded-xl p-4 border border-border/50 shadow-sm hover:shadow-md hover:border-primary/30 transition-all"
                  >
                    <div className="flex items-start gap-3">
                      <div className="p-2 bg-accent/20 rounded-lg">
                        <FileText className="h-5 w-5 text-accent-foreground" />
                      </div>
                      <div className={cn('flex-1', isUrdu && 'text-right')}>
                        <h3 className={cn('font-semibold text-foreground', isUrdu && 'font-urdu')}>
                          {template.title}
                        </h3>
                        <p className={cn('text-sm text-muted-foreground mt-1 line-clamp-2', isUrdu && 'font-urdu')}>
                          {template.description}
                        </p>
                        {template.tags && template.tags.length > 0 && (
                          <div className="flex flex-wrap gap-1 mt-2">
                            {template.tags.slice(0, 3).map((tag) => (
                              <span key={tag} className="px-2 py-0.5 bg-muted text-muted-foreground text-xs rounded-full">
                                {tag}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                      <ChevronRight className="h-5 w-5 text-muted-foreground flex-shrink-0" />
                    </div>
                  </Link>
                ))
              )}
            </TabsContent>
          </>
        )}
      </Tabs>
    </div>
  );
}
