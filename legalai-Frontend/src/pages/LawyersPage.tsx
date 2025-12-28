import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { useAuth } from '@/contexts/AuthContext';
import { Lawyer, PaginationMeta } from '@/lib/types';
import { cn } from '@/lib/utils';
import { Phone, Mail, Briefcase, Loader2, User, ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useNavigate } from 'react-router-dom';

export default function LawyersPage() {
  const [lawyers, setLawyers] = useState<Lawyer[]>([]);
  const [meta, setMeta] = useState<PaginationMeta | null>(null);
  const [page, setPage] = useState(1);
  const [isLoading, setIsLoading] = useState(true);
  const { t, isUrdu } = useLanguage();
  const { isAuthenticated } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (isAuthenticated) {
      loadLawyers();
    } else {
      setIsLoading(false);
    }
  }, [isAuthenticated, page]);

  const loadLawyers = async () => {
    setIsLoading(true);
    const response = await api.getLawyers(page, 20);
    if (response.data) {
      const data = response.data as any;
      setLawyers(data.items || data || []);
      setMeta(data.meta || null);
    }
    setIsLoading(false);
  };

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center p-4">
        <Briefcase className="h-12 w-12 text-muted-foreground/50 mb-4" />
        <p className={cn('text-muted-foreground text-center mb-4', isUrdu && 'font-urdu')}>
          {t('Login to find lawyers', 'وکیل تلاش کرنے کے لیے لاگ ان کریں')}
        </p>
        <Button onClick={() => navigate('/login')}>
          {t('Login', 'لاگ ان')}
        </Button>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur-sm border-b border-border px-4 py-4">
        <h1 className={cn('text-xl font-bold text-foreground', isUrdu && 'font-urdu text-right')}>
          {t('Find a Lawyer', 'وکیل تلاش کریں')}
        </h1>
        <p className={cn('text-sm text-muted-foreground', isUrdu && 'font-urdu text-right')}>
          {t('Connect with legal professionals', 'قانونی ماہرین سے رابطہ کریں')}
        </p>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : lawyers.length === 0 ? (
        <div className={cn('text-center py-20', isUrdu && 'font-urdu')}>
          <User className="h-12 w-12 mx-auto text-muted-foreground/50 mb-4" />
          <p className="text-muted-foreground">
            {t('No lawyers available at the moment', 'ابھی کوئی وکیل دستیاب نہیں')}
          </p>
        </div>
      ) : (
        <div className="p-4 space-y-4">
          {lawyers.map((lawyer) => (
            <div key={lawyer.id} className="bg-card rounded-xl p-4 border border-border/50 shadow-sm">
              <div className="flex items-start gap-4">
                <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center overflow-hidden flex-shrink-0">
                  {lawyer.profilePicturePath ? (
                    <img 
                      src={lawyer.profilePicturePath} 
                      alt={lawyer.name}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <User className="h-8 w-8 text-primary" />
                  )}
                </div>
                <div className={cn('flex-1', isUrdu && 'text-right')}>
                  <h3 className={cn('font-semibold text-foreground text-lg', isUrdu && 'font-urdu')}>
                    {lawyer.name}
                  </h3>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="px-2 py-0.5 bg-primary/10 text-primary text-xs rounded-full">
                      {lawyer.category}
                    </span>
                  </div>
                  <div className="mt-3 space-y-1">
                    <a 
                      href={`tel:${lawyer.phone}`}
                      className="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
                    >
                      <Phone className="h-4 w-4" />
                      {lawyer.phone}
                    </a>
                    <a 
                      href={`mailto:${lawyer.email}`}
                      className="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
                    >
                      <Mail className="h-4 w-4" />
                      {lawyer.email}
                    </a>
                  </div>
                </div>
              </div>
              <div className="flex gap-2 mt-4">
                <Button 
                  variant="outline" 
                  className="flex-1"
                  onClick={() => window.open(`tel:${lawyer.phone}`)}
                >
                  <Phone className="h-4 w-4 mr-2" />
                  {t('Call', 'کال')}
                </Button>
                <Button 
                  className="flex-1 gradient-primary"
                  onClick={() => window.open(`mailto:${lawyer.email}`)}
                >
                  <Mail className="h-4 w-4 mr-2" />
                  {t('Email', 'ای میل')}
                </Button>
              </div>
            </div>
          ))}

          {/* Pagination */}
          {meta && meta.totalPages > 1 && (
            <div className="flex items-center justify-center gap-4 pt-4">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={!meta.hasPrev}
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <span className="text-sm text-muted-foreground">
                {page} / {meta.totalPages}
              </span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage(p => p + 1)}
                disabled={!meta.hasNext}
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
