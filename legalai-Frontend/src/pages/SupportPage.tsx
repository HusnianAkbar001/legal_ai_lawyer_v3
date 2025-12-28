import { useState } from 'react';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { useAuth } from '@/contexts/AuthContext';
import { cn } from '@/lib/utils';
import { MessageSquare, Star, Send, Loader2, ArrowLeft, Phone, Mail } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useToast } from '@/hooks/use-toast';
import { useNavigate, Link } from 'react-router-dom';

export default function SupportPage() {
  const [activeTab, setActiveTab] = useState('contact');
  const { t, isUrdu } = useLanguage();
  const { user, isAuthenticated } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();

  // Contact form state
  const [contactForm, setContactForm] = useState({
    fullName: user?.name || '',
    email: user?.email || '',
    phone: user?.phone || '',
    subject: '',
    description: '',
  });
  const [isSubmittingContact, setIsSubmittingContact] = useState(false);

  // Feedback form state
  const [feedbackForm, setFeedbackForm] = useState({
    rating: 0,
    comment: '',
  });
  const [isSubmittingFeedback, setIsSubmittingFeedback] = useState(false);

  const handleContactSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!isAuthenticated) {
      toast({
        title: t('Login required', 'لاگ ان ضروری ہے'),
        description: t('Please login to contact support.', 'سپورٹ سے رابطے کے لیے لاگ ان کریں۔'),
        variant: 'destructive',
      });
      navigate('/login');
      return;
    }

    setIsSubmittingContact(true);
    const response = await api.submitContactMessage(contactForm);
    
    if (response.error) {
      toast({
        title: t('Error', 'خرابی'),
        description: response.error,
        variant: 'destructive',
      });
    } else {
      toast({
        title: t('Message sent!', 'پیغام بھیج دیا گیا!'),
        description: t('We will get back to you soon.', 'ہم جلد آپ سے رابطہ کریں گے۔'),
      });
      setContactForm({ ...contactForm, subject: '', description: '' });
    }
    setIsSubmittingContact(false);
  };

  const handleFeedbackSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!isAuthenticated) {
      toast({
        title: t('Login required', 'لاگ ان ضروری ہے'),
        variant: 'destructive',
      });
      navigate('/login');
      return;
    }

    if (feedbackForm.rating === 0) {
      toast({
        title: t('Rating required', 'ریٹنگ ضروری ہے'),
        description: t('Please select a rating.', 'براہ کرم ریٹنگ منتخب کریں۔'),
        variant: 'destructive',
      });
      return;
    }

    setIsSubmittingFeedback(true);
    const response = await api.submitFeedback(feedbackForm.rating, feedbackForm.comment);
    
    if (response.error) {
      toast({
        title: t('Error', 'خرابی'),
        description: response.error,
        variant: 'destructive',
      });
    } else {
      toast({
        title: t('Thank you!', 'شکریہ!'),
        description: t('Your feedback has been submitted.', 'آپ کی رائے موصول ہو گئی۔'),
      });
      setFeedbackForm({ rating: 0, comment: '' });
    }
    setIsSubmittingFeedback(false);
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur-sm border-b border-border px-4 py-4">
        <Link to="/profile" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-3">
          <ArrowLeft className="h-5 w-5" />
          <span className={cn('text-sm', isUrdu && 'font-urdu')}>{t('Back', 'واپس')}</span>
        </Link>
        <h1 className={cn('text-xl font-bold text-foreground', isUrdu && 'font-urdu text-right')}>
          {t('Help & Support', 'مدد اور سپورٹ')}
        </h1>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="px-4 pt-4">
        <TabsList className="grid w-full grid-cols-2 h-11 mb-4">
          <TabsTrigger value="contact" className="gap-1.5">
            <MessageSquare className="h-4 w-4" />
            <span className={cn('text-xs', isUrdu && 'font-urdu')}>{t('Contact', 'رابطہ')}</span>
          </TabsTrigger>
          <TabsTrigger value="feedback" className="gap-1.5">
            <Star className="h-4 w-4" />
            <span className={cn('text-xs', isUrdu && 'font-urdu')}>{t('Feedback', 'رائے')}</span>
          </TabsTrigger>
        </TabsList>

        <TabsContent value="contact" className="mt-0">
          <form onSubmit={handleContactSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label className={cn(isUrdu && 'font-urdu')}>{t('Full Name', 'پورا نام')}</Label>
              <Input
                value={contactForm.fullName}
                onChange={(e) => setContactForm(prev => ({ ...prev, fullName: e.target.value }))}
                className={cn(isUrdu && 'font-urdu text-right')}
                required
              />
            </div>

            <div className="space-y-2">
              <Label className={cn(isUrdu && 'font-urdu')}>{t('Email', 'ای میل')}</Label>
              <Input
                type="email"
                value={contactForm.email}
                onChange={(e) => setContactForm(prev => ({ ...prev, email: e.target.value }))}
                required
              />
            </div>

            <div className="space-y-2">
              <Label className={cn(isUrdu && 'font-urdu')}>{t('Phone', 'فون')}</Label>
              <Input
                value={contactForm.phone}
                onChange={(e) => setContactForm(prev => ({ ...prev, phone: e.target.value }))}
                required
              />
            </div>

            <div className="space-y-2">
              <Label className={cn(isUrdu && 'font-urdu')}>{t('Subject', 'موضوع')}</Label>
              <Input
                value={contactForm.subject}
                onChange={(e) => setContactForm(prev => ({ ...prev, subject: e.target.value }))}
                placeholder={t('What is this about?', 'یہ کس بارے میں ہے؟')}
                className={cn(isUrdu && 'font-urdu text-right')}
                required
              />
            </div>

            <div className="space-y-2">
              <Label className={cn(isUrdu && 'font-urdu')}>{t('Message', 'پیغام')}</Label>
              <Textarea
                value={contactForm.description}
                onChange={(e) => setContactForm(prev => ({ ...prev, description: e.target.value }))}
                placeholder={t('Describe your issue or question...', 'اپنا مسئلہ یا سوال بیان کریں...')}
                className={cn('min-h-[120px]', isUrdu && 'font-urdu text-right')}
                required
              />
            </div>

            <Button 
              type="submit" 
              className="w-full h-12 gradient-primary"
              disabled={isSubmittingContact}
            >
              {isSubmittingContact ? (
                <Loader2 className="h-5 w-5 animate-spin" />
              ) : (
                <>
                  <Send className="h-5 w-5 mr-2" />
                  <span className={cn(isUrdu && 'font-urdu')}>{t('Send Message', 'پیغام بھیجیں')}</span>
                </>
              )}
            </Button>
          </form>
        </TabsContent>

        <TabsContent value="feedback" className="mt-0">
          <form onSubmit={handleFeedbackSubmit} className="space-y-6">
            <div className="space-y-3">
              <Label className={cn(isUrdu && 'font-urdu')}>{t('How would you rate this app?', 'آپ اس ایپ کو کیسی ریٹنگ دیں گے؟')}</Label>
              <div className="flex justify-center gap-2">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    type="button"
                    onClick={() => setFeedbackForm(prev => ({ ...prev, rating: star }))}
                    className="p-1 transition-transform hover:scale-110"
                  >
                    <Star 
                      className={cn(
                        'h-10 w-10 transition-colors',
                        star <= feedbackForm.rating 
                          ? 'fill-accent text-accent' 
                          : 'text-muted-foreground/30'
                      )} 
                    />
                  </button>
                ))}
              </div>
              <p className={cn('text-center text-sm text-muted-foreground', isUrdu && 'font-urdu')}>
                {feedbackForm.rating === 0 && t('Tap to rate', 'ریٹنگ کے لیے ٹیپ کریں')}
                {feedbackForm.rating === 1 && t('Poor', 'خراب')}
                {feedbackForm.rating === 2 && t('Fair', 'ٹھیک')}
                {feedbackForm.rating === 3 && t('Good', 'اچھا')}
                {feedbackForm.rating === 4 && t('Very Good', 'بہت اچھا')}
                {feedbackForm.rating === 5 && t('Excellent', 'بہترین')}
              </p>
            </div>

            <div className="space-y-2">
              <Label className={cn(isUrdu && 'font-urdu')}>{t('Your feedback', 'آپ کی رائے')}</Label>
              <Textarea
                value={feedbackForm.comment}
                onChange={(e) => setFeedbackForm(prev => ({ ...prev, comment: e.target.value }))}
                placeholder={t('Tell us what you think...', 'ہمیں بتائیں آپ کیا سوچتے ہیں...')}
                className={cn('min-h-[120px]', isUrdu && 'font-urdu text-right')}
                required
              />
            </div>

            <Button 
              type="submit" 
              className="w-full h-12 gradient-primary"
              disabled={isSubmittingFeedback}
            >
              {isSubmittingFeedback ? (
                <Loader2 className="h-5 w-5 animate-spin" />
              ) : (
                <>
                  <Star className="h-5 w-5 mr-2" />
                  <span className={cn(isUrdu && 'font-urdu')}>{t('Submit Feedback', 'رائے جمع کریں')}</span>
                </>
              )}
            </Button>
          </form>
        </TabsContent>
      </Tabs>
    </div>
  );
}
