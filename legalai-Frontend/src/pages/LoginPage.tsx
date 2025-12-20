import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useLanguage } from '@/contexts/LanguageContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Scale, Mail, Lock, Eye, EyeOff, ArrowLeft } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();
  const { t, isUrdu } = useLanguage();
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    const result = await login(email, password);
    
    if (result.success) {
      toast({
        title: t('Welcome back!', 'خوش آمدید!'),
        description: t('You have successfully logged in.', 'آپ کامیابی سے لاگ ان ہو گئے۔'),
      });
      navigate('/');
    } else {
      toast({
        title: t('Login failed', 'لاگ ان ناکام'),
        description: result.error || t('Please check your credentials.', 'براہ کرم اپنی تفصیلات چیک کریں۔'),
        variant: 'destructive',
      });
    }
    
    setIsLoading(false);
  };

  return (
    <div className="min-h-screen gradient-hero flex flex-col">
      {/* Header */}
      <div className="p-4">
        <Link to="/" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors">
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
          {t('Welcome Back', 'خوش آمدید')}
        </h1>
        <p className={cn(
          'text-center text-muted-foreground mb-8',
          isUrdu && 'font-urdu'
        )}>
          {t('Sign in to continue', 'جاری رکھنے کے لیے سائن ان کریں')}
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

          <div className="space-y-2">
            <Label htmlFor="password" className={cn(isUrdu && 'font-urdu')}>
              {t('Password', 'پاس ورڈ')}
            </Label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
              <Input
                id="password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="pl-11 pr-11 h-12 rounded-xl"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
              </button>
            </div>
          </div>

          <div className="flex justify-end">
            <Link 
              to="/forgot-password" 
              className={cn('text-sm text-primary hover:underline', isUrdu && 'font-urdu')}
            >
              {t('Forgot password?', 'پاس ورڈ بھول گئے؟')}
            </Link>
          </div>

          <Button 
            type="submit" 
            className="w-full h-12 rounded-xl text-base font-semibold gradient-primary hover:opacity-90 transition-opacity"
            disabled={isLoading}
          >
            {isLoading ? (
              <div className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
            ) : (
              <span className={cn(isUrdu && 'font-urdu')}>{t('Sign In', 'سائن ان')}</span>
            )}
          </Button>
        </form>

        <p className={cn(
          'text-center text-muted-foreground mt-8',
          isUrdu && 'font-urdu'
        )}>
          {t("Don't have an account?", 'اکاؤنٹ نہیں ہے؟')}{' '}
          <Link to="/signup" className="text-primary font-semibold hover:underline">
            {t('Sign Up', 'سائن اپ')}
          </Link>
        </p>
      </div>
    </div>
  );
}
