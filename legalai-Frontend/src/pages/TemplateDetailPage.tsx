import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { useAuth } from '@/contexts/AuthContext';
import { Template } from '@/lib/types';
import { cn } from '@/lib/utils';
import { ArrowLeft, FileText, Loader2, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';

export default function TemplateDetailPage() {
  const { templateId } = useParams<{ templateId: string }>();
  const [template, setTemplate] = useState<Template | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isGenerating, setIsGenerating] = useState(false);
  const [formData, setFormData] = useState<Record<string, string>>({});
  const { t, isUrdu } = useLanguage();
  const { user, isAuthenticated } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    loadTemplate();
  }, [templateId]);

  const loadTemplate = async () => {
    if (!templateId) return;
    setIsLoading(true);
    const response = await api.getTemplate(parseInt(templateId));
    if (response.data) {
      const tmpl = (response.data as any).template || response.data as Template;
      setTemplate(tmpl);
      
      // Extract placeholders from template body
      const placeholders = tmpl.body.match(/\{\{(\w+)\}\}/g) || [];
      const initialData: Record<string, string> = {};
      placeholders.forEach((p: string) => {
        const key = p.replace(/\{\{|\}\}/g, '');
        initialData[key] = '';
      });
      setFormData(initialData);
    }
    setIsLoading(false);
  };

  const handleGenerate = async () => {
    if (!isAuthenticated) {
      toast({
        title: t('Login required', 'لاگ ان ضروری ہے'),
        description: t('Please login to generate documents.', 'دستاویز بنانے کے لیے لاگ ان کریں۔'),
        variant: 'destructive',
      });
      navigate('/login');
      return;
    }

    if (!template) return;

    setIsGenerating(true);

    const userSnapshot = {
      name: user?.name || '',
      cnic: user?.cnic || '',
      phone: user?.phone || '',
    };

    const response = await api.generateDraft(template.id, formData, userSnapshot);

    if (response.error) {
      toast({
        title: t('Generation failed', 'بنانے میں ناکامی'),
        description: response.error,
        variant: 'destructive',
      });
    } else {
      toast({
        title: t('Draft created!', 'دستاویز بن گئی!'),
        description: t('Your document has been generated.', 'آپ کی دستاویز بن گئی ہے۔'),
      });
      navigate('/drafts');
    }

    setIsGenerating(false);
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!template) {
    return (
      <div className="min-h-screen bg-background p-4">
        <Link to="/drafts" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground">
          <ArrowLeft className="h-5 w-5" />
          <span>{t('Back', 'واپس')}</span>
        </Link>
        <div className={cn('text-center py-20 text-muted-foreground', isUrdu && 'font-urdu')}>
          {t('Template not found', 'ٹیمپلیٹ نہیں ملا')}
        </div>
      </div>
    );
  }

  const placeholderKeys = Object.keys(formData);

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur-sm border-b border-border px-4 py-4">
        <Link to="/drafts" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-3">
          <ArrowLeft className="h-5 w-5" />
          <span className={cn('text-sm', isUrdu && 'font-urdu')}>{t('Back', 'واپس')}</span>
        </Link>
        <div className="flex items-start gap-3">
          <div className="p-2 bg-accent/20 rounded-lg">
            <FileText className="h-6 w-6 text-accent-foreground" />
          </div>
          <div className={cn('flex-1', isUrdu && 'text-right')}>
            <h1 className={cn('text-lg font-bold text-foreground', isUrdu && 'font-urdu')}>
              {template.title}
            </h1>
            <p className={cn('text-sm text-muted-foreground', isUrdu && 'font-urdu')}>
              {template.description}
            </p>
          </div>
        </div>
      </div>

      <div className="p-4 space-y-6">
        {/* Form Fields */}
        {placeholderKeys.length > 0 && (
          <div className="space-y-4">
            <h2 className={cn('text-base font-semibold text-foreground', isUrdu && 'font-urdu text-right')}>
              {t('Fill in the details', 'تفصیلات بھریں')}
            </h2>
            
            {placeholderKeys.map((key) => (
              <div key={key} className="space-y-2">
                <Label className={cn('capitalize', isUrdu && 'font-urdu')}>
                  {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                </Label>
                {key.toLowerCase().includes('description') || key.toLowerCase().includes('details') ? (
                  <Textarea
                    value={formData[key]}
                    onChange={(e) => setFormData(prev => ({ ...prev, [key]: e.target.value }))}
                    placeholder={`Enter ${key}`}
                    className={cn('min-h-[100px]', isUrdu && 'font-urdu text-right')}
                  />
                ) : (
                  <Input
                    value={formData[key]}
                    onChange={(e) => setFormData(prev => ({ ...prev, [key]: e.target.value }))}
                    placeholder={`Enter ${key}`}
                    className={cn(isUrdu && 'font-urdu text-right')}
                  />
                )}
              </div>
            ))}
          </div>
        )}

        {/* Template Preview */}
        <div className="space-y-2">
          <h2 className={cn('text-base font-semibold text-foreground', isUrdu && 'font-urdu text-right')}>
            {t('Template Preview', 'ٹیمپلیٹ کا جائزہ')}
          </h2>
          <div className={cn(
            'bg-card rounded-xl p-4 border border-border/50 text-sm text-muted-foreground whitespace-pre-wrap',
            isUrdu && 'font-urdu text-right'
          )}>
            {template.body}
          </div>
        </div>

        {/* Generate Button */}
        <Button
          onClick={handleGenerate}
          disabled={isGenerating}
          className="w-full h-12 rounded-xl text-base font-semibold gradient-primary hover:opacity-90 transition-opacity"
        >
          {isGenerating ? (
            <Loader2 className="h-5 w-5 animate-spin" />
          ) : (
            <>
              <Sparkles className="h-5 w-5 mr-2" />
              <span className={cn(isUrdu && 'font-urdu')}>{t('Generate Document', 'دستاویز بنائیں')}</span>
            </>
          )}
        </Button>
      </div>
    </div>
  );
}
