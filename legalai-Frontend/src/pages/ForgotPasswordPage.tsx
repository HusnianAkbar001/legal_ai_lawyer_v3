import { useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Scale, Mail, ArrowLeft, Loader2, CheckCircle } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const { t, isUrdu } = useLanguage();
  const { toast } = useToast();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    const result = await api.forgotPassword(email);
    
    if (result.error) {
      toast({
        title: t('Error', 'خرابی'),
        description: result.error,
        variant: 'destructive',
      });
    } else {
      setIsSuccess(true);
    }
    
    setIsLoading(false);
  };

  if (isSuccess) {
    return (
      <div className="min-h-screen gradient-hero flex flex-col items-center justify-center px-6">
        <div className="p-4 rounded-full bg-success/20 mb-6">
          <CheckCircle className="h-12 w-12 text-success" />
        </div>
        <h1 className={cn(
          'text-2xl font-bold text-center text-foreground mb-2',
          isUrdu && 'font-urdu'
        )}>
          {t('Email Sent!', 'ای میل بھیج دی گئی!')}
        </h1>
        <p className={cn(
          'text-center text-muted-foreground mb-8 max-w-xs',
          isUrdu && 'font-urdu'
        )}>
          {t(
            'Please check your email for password reset instructions.',
            'براہ کرم پاس ورڈ ری سیٹ کی ہدایات کے لیے اپنا ای میل چیک کریں۔'
          )}
        </p>
        <Link to="/login">
          <Button className="gradient-primary">
            {t('Back to Login', 'لاگ ان پر واپس جائیں')}
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen gradient-hero flex flex-col">
      {/* Header */}
      <div className="p-4">
        <Link to="/login" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors">
          <ArrowLeft className="h-5 w-5" />
          <span className={cn(isUrdu && 'font-urdu')}>{t('Back', 'واپس')}</span>
        </Link>
      </div>

      <div className="flex-1 flex flex-col justify-center px-6 pb-12">
        {/* Logo */}
        <div className="flex justify-center mb-8">
          <div className="p-4 rounded-2xl gradient-primary shadow-glow">
            <Scale className="h-12 w-12 text-primary-foreground" />
          </div>
        </div>

        <h1 className={cn(
          'text-2xl font-bold text-center text-foreground mb-2',
          isUrdu && 'font-urdu'
        )}>
          {t('Forgot Password?', 'پاس ورڈ بھول گئے؟')}
        </h1>
        <p className={cn(
          'text-center text-muted-foreground mb-8',
          isUrdu && 'font-urdu'
        )}>
          {t(
            'Enter your email and we\'ll send you reset instructions.',
            'اپنا ای میل درج کریں اور ہم آپ کو ری سیٹ ہدایات بھیجیں گے۔'
          )}
        </p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <div className="space-y-2">
            <Label htmlFor="email" className={cn(isUrdu && 'font-urdu')}>
              {t('Email', 'ای میل')}
            </Label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="email@example.com"
                className="pl-11 h-12 rounded-xl"
                required
              />
            </div>
          </div>

          <Button 
            type="submit" 
            className="w-full h-12 rounded-xl text-base font-semibold gradient-primary hover:opacity-90 transition-opacity"
            disabled={isLoading}
          >
            {isLoading ? (
              <Loader2 className="h-5 w-5 animate-spin" />
            ) : (
              <span className={cn(isUrdu && 'font-urdu')}>{t('Send Reset Link', 'ری سیٹ لنک بھیجیں')}</span>
            )}
          </Button>
        </form>

        <p className={cn(
          'text-center text-muted-foreground mt-8',
          isUrdu && 'font-urdu'
        )}>
          {t('Remember your password?', 'پاس ورڈ یاد ہے؟')}{' '}
          <Link to="/login" className="text-primary font-semibold hover:underline">
            {t('Sign In', 'سائن ان')}
          </Link>
        </p>
      </div>
    </div>
  );
}
