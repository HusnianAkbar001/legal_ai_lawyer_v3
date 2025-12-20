import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { useAuth } from '@/contexts/AuthContext';
import { Reminder } from '@/lib/types';
import { cn } from '@/lib/utils';
import { Bell, Plus, Loader2, Calendar, Trash2, Check, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { useNavigate } from 'react-router-dom';

export default function RemindersPage() {
  const [reminders, setReminders] = useState<Reminder[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [newReminder, setNewReminder] = useState({
    title: '',
    notes: '',
    scheduledAt: '',
  });
  const { t, isUrdu } = useLanguage();
  const { isAuthenticated } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    if (isAuthenticated) {
      loadReminders();
    } else {
      setIsLoading(false);
    }
  }, [isAuthenticated]);

  const loadReminders = async () => {
    setIsLoading(true);
    const response = await api.getReminders();
    if (response.data) {
      setReminders((response.data as any).reminders || response.data as Reminder[] || []);
    }
    setIsLoading(false);
  };

  const handleCreate = async () => {
    if (!newReminder.title || !newReminder.scheduledAt) {
      toast({
        title: t('Missing fields', 'خالی فیلڈز'),
        description: t('Please fill title and date.', 'عنوان اور تاریخ بھریں۔'),
        variant: 'destructive',
      });
      return;
    }

    const response = await api.createReminder({
      title: newReminder.title,
      notes: newReminder.notes,
      scheduledAt: new Date(newReminder.scheduledAt).toISOString(),
    });

    if (response.error) {
      toast({
        title: t('Error', 'خرابی'),
        description: response.error,
        variant: 'destructive',
      });
    } else {
      toast({
        title: t('Reminder created', 'یاد دہانی بن گئی'),
      });
      setIsDialogOpen(false);
      setNewReminder({ title: '', notes: '', scheduledAt: '' });
      loadReminders();
    }
  };

  const handleToggleDone = async (reminder: Reminder) => {
    await api.updateReminder(reminder.id, { isDone: !reminder.isDone });
    loadReminders();
  };

  const handleDelete = async (reminderId: number) => {
    await api.deleteReminder(reminderId);
    setReminders(prev => prev.filter(r => r.id !== reminderId));
    toast({
      title: t('Deleted', 'حذف ہو گیا'),
    });
  };

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center p-4">
        <Bell className="h-12 w-12 text-muted-foreground/50 mb-4" />
        <p className={cn('text-muted-foreground text-center mb-4', isUrdu && 'font-urdu')}>
          {t('Login to manage your reminders', 'یاد دہانیاں دیکھنے کے لیے لاگ ان کریں')}
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
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur-sm border-b border-border px-4 py-4 flex items-center justify-between">
        <div>
          <h1 className={cn('text-xl font-bold text-foreground', isUrdu && 'font-urdu text-right')}>
            {t('Reminders', 'یاد دہانیاں')}
          </h1>
          <p className={cn('text-sm text-muted-foreground', isUrdu && 'font-urdu text-right')}>
            {t('Court dates & deadlines', 'عدالتی تاریخیں')}
          </p>
        </div>

        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button size="sm" className="gradient-primary">
              <Plus className="h-4 w-4 mr-1" />
              {t('Add', 'شامل')}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className={cn(isUrdu && 'font-urdu text-right')}>
                {t('New Reminder', 'نئی یاد دہانی')}
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-4 mt-4">
              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('Title', 'عنوان')}</Label>
                <Input
                  value={newReminder.title}
                  onChange={(e) => setNewReminder(prev => ({ ...prev, title: e.target.value }))}
                  placeholder={t('Court hearing', 'عدالتی سماعت')}
                  className={cn(isUrdu && 'font-urdu text-right')}
                />
              </div>
              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('Date & Time', 'تاریخ و وقت')}</Label>
                <Input
                  type="datetime-local"
                  value={newReminder.scheduledAt}
                  onChange={(e) => setNewReminder(prev => ({ ...prev, scheduledAt: e.target.value }))}
                />
              </div>
              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('Notes', 'نوٹس')}</Label>
                <Textarea
                  value={newReminder.notes}
                  onChange={(e) => setNewReminder(prev => ({ ...prev, notes: e.target.value }))}
                  placeholder={t('Additional notes...', 'اضافی نوٹس...')}
                  className={cn(isUrdu && 'font-urdu text-right')}
                />
              </div>
              <Button onClick={handleCreate} className="w-full gradient-primary">
                {t('Create Reminder', 'یاد دہانی بنائیں')}
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : reminders.length === 0 ? (
        <div className={cn('text-center py-20', isUrdu && 'font-urdu')}>
          <Calendar className="h-12 w-12 mx-auto text-muted-foreground/50 mb-4" />
          <p className="text-muted-foreground">
            {t('No reminders yet', 'ابھی کوئی یاد دہانی نہیں')}
          </p>
        </div>
      ) : (
        <div className="p-4 space-y-3">
          {reminders.map((reminder) => (
            <div
              key={reminder.id}
              className={cn(
                'bg-card rounded-xl p-4 border border-border/50 shadow-sm',
                reminder.isDone && 'opacity-60'
              )}
            >
              <div className="flex items-start gap-3">
                <button
                  onClick={() => handleToggleDone(reminder)}
                  className={cn(
                    'p-2 rounded-full border-2 transition-colors flex-shrink-0 mt-0.5',
                    reminder.isDone
                      ? 'bg-primary border-primary text-primary-foreground'
                      : 'border-muted-foreground/30 hover:border-primary'
                  )}
                >
                  {reminder.isDone && <Check className="h-3 w-3" />}
                </button>
                <div className={cn('flex-1', isUrdu && 'text-right')}>
                  <h3 className={cn(
                    'font-semibold text-foreground',
                    reminder.isDone && 'line-through',
                    isUrdu && 'font-urdu'
                  )}>
                    {reminder.title}
                  </h3>
                  {reminder.notes && (
                    <p className={cn('text-sm text-muted-foreground mt-1', isUrdu && 'font-urdu')}>
                      {reminder.notes}
                    </p>
                  )}
                  <div className="flex items-center gap-2 mt-2 text-xs text-muted-foreground">
                    <Calendar className="h-3 w-3" />
                    {new Date(reminder.scheduledAt).toLocaleString()}
                  </div>
                </div>
                <button
                  onClick={() => handleDelete(reminder.id)}
                  className="p-2 text-muted-foreground hover:text-destructive transition-colors"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
