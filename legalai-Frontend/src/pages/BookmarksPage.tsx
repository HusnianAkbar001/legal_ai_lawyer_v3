import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { useAuth } from '@/contexts/AuthContext';
import { Bookmark } from '@/lib/types';
import { cn } from '@/lib/utils';
import { Bookmark as BookmarkIcon, Loader2, Trash2, BookOpen, FileText, Route, ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useNavigate, Link } from 'react-router-dom';
import { useToast } from '@/hooks/use-toast';

export default function BookmarksPage() {
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const { t, isUrdu } = useLanguage();
  const { isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    if (isAuthenticated) {
      loadBookmarks();
    } else {
      setIsLoading(false);
    }
  }, [isAuthenticated]);

  const loadBookmarks = async () => {
    setIsLoading(true);
    const response = await api.getBookmarks();
    if (response.data) {
      setBookmarks((response.data as any).bookmarks || response.data as Bookmark[] || []);
    }
    setIsLoading(false);
  };

  const handleDelete = async (bookmarkId: number) => {
    await api.deleteBookmark(bookmarkId);
    setBookmarks(prev => prev.filter(b => b.id !== bookmarkId));
    toast({
      title: t('Removed', 'ہٹا دیا گیا'),
    });
  };

  const getIcon = (itemType: string) => {
    switch (itemType) {
      case 'right': return BookOpen;
      case 'template': return FileText;
      case 'pathway': return Route;
      default: return BookmarkIcon;
    }
  };

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center p-4">
        <BookmarkIcon className="h-12 w-12 text-muted-foreground/50 mb-4" />
        <p className={cn('text-muted-foreground text-center mb-4', isUrdu && 'font-urdu')}>
          {t('Login to see your bookmarks', 'بک مارکس دیکھنے کے لیے لاگ ان کریں')}
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
        <Link to="/profile" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-3">
          <ArrowLeft className="h-5 w-5" />
          <span className={cn('text-sm', isUrdu && 'font-urdu')}>{t('Back', 'واپس')}</span>
        </Link>
        <h1 className={cn('text-xl font-bold text-foreground', isUrdu && 'font-urdu text-right')}>
          {t('Bookmarks', 'بک مارکس')}
        </h1>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : bookmarks.length === 0 ? (
        <div className={cn('text-center py-20', isUrdu && 'font-urdu')}>
          <BookmarkIcon className="h-12 w-12 mx-auto text-muted-foreground/50 mb-4" />
          <p className="text-muted-foreground">
            {t('No bookmarks yet', 'ابھی کوئی بک مارکس نہیں')}
          </p>
          <p className="text-sm text-muted-foreground mt-2">
            {t('Save rights, templates, and pathways for quick access', 'فوری رسائی کے لیے حقوق، ٹیمپلیٹس اور راستے محفوظ کریں')}
          </p>
        </div>
      ) : (
        <div className="p-4 space-y-3">
          {bookmarks.map((bookmark) => {
            const Icon = getIcon(bookmark.itemType);
            return (
              <div key={bookmark.id} className="bg-card rounded-xl p-4 border border-border/50 shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-primary/10 rounded-lg">
                    <Icon className="h-5 w-5 text-primary" />
                  </div>
                  <div className={cn('flex-1', isUrdu && 'text-right')}>
                    <p className="text-sm text-muted-foreground capitalize">
                      {bookmark.itemType}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      ID: {bookmark.itemId}
                    </p>
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => handleDelete(bookmark.id)}
                    className="text-destructive hover:text-destructive"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
