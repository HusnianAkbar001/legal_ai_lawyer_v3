import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Scale, ArrowLeft, User, Mail, Lock, Phone, CreditCard, MapPin, Eye, EyeOff } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';

export default function SignupPage() {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    cnic: '',
    password: '',
    confirmPassword: '',
    city: '',
    gender: '',
    age: '',
  });
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const { t, isUrdu } = useLanguage();
  const navigate = useNavigate();
  const { toast } = useToast();

  const updateField = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (step === 1) {
      if (!formData.name || !formData.email || !formData.phone) {
        toast({
          title: t('Missing fields', 'خالی فیلڈز'),
          description: t('Please fill all required fields.', 'براہ کرم تمام ضروری فیلڈز بھریں۔'),
          variant: 'destructive',
        });
        return;
      }
      setStep(2);
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      toast({
        title: t('Password mismatch', 'پاس ورڈ مختلف ہیں'),
        description: t('Passwords do not match.', 'پاس ورڈز ایک جیسے نہیں ہیں۔'),
        variant: 'destructive',
      });
      return;
    }

    setIsLoading(true);

    const result = await api.signup({
      name: formData.name,
      email: formData.email,
      phone: formData.phone,
      cnic: formData.cnic,
      password: formData.password,
      city: formData.city,
      gender: formData.gender,
      age: parseInt(formData.age) || 18,
    });

    if (result.error) {
      toast({
        title: t('Signup failed', 'سائن اپ ناکام'),
        description: result.error,
        variant: 'destructive',
      });
    } else {
      toast({
        title: t('Account created!', 'اکاؤنٹ بن گیا!'),
        description: t('Please check your email to verify your account.', 'براہ کرم اپنا ای میل چیک کریں۔'),
      });
      navigate('/login');
    }

    setIsLoading(false);
  };

  return (
    <div className="min-h-screen gradient-hero flex flex-col">
      {/* Header */}
      <div className="p-4 flex items-center justify-between">
        <button 
          onClick={() => step > 1 ? setStep(step - 1) : navigate(-1)}
          className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="h-5 w-5" />
          <span className={cn(isUrdu && 'font-urdu')}>{t('Back', 'واپس')}</span>
        </button>
        <span className="text-sm text-muted-foreground">
          {t(`Step ${step} of 2`, `مرحلہ ${step} / 2`)}
        </span>
      </div>

      <div className="flex-1 px-6 pb-8 overflow-y-auto">
        {/* Logo */}
        <div className="flex justify-center mb-6">
          <div className="p-3 rounded-xl gradient-primary shadow-glow">
            <Scale className="h-8 w-8 text-primary-foreground" />
          </div>
        </div>

        <h1 className={cn(
          'text-xl font-bold text-center text-foreground mb-1',
          isUrdu && 'font-urdu'
        )}>
          {t('Create Account', 'اکاؤنٹ بنائیں')}
        </h1>
        <p className={cn(
          'text-center text-muted-foreground mb-6 text-sm',
          isUrdu && 'font-urdu'
        )}>
          {step === 1 
            ? t('Enter your personal details', 'اپنی ذاتی تفصیلات درج کریں')
            : t('Set up your security', 'اپنی سیکیورٹی سیٹ کریں')
          }
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          {step === 1 ? (
            <>
              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('Full Name', 'پورا نام')} *</Label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                  <Input
                    value={formData.name}
                    onChange={(e) => updateField('name', e.target.value)}
                    placeholder={t('Enter your name', 'اپنا نام لکھیں')}
                    className="pl-11 h-12 rounded-xl"
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('Email', 'ای میل')} *</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                  <Input
                    type="email"
                    value={formData.email}
                    onChange={(e) => updateField('email', e.target.value)}
                    placeholder="email@example.com"
                    className="pl-11 h-12 rounded-xl"
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('Phone', 'فون نمبر')} *</Label>
                <div className="relative">
                  <Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                  <Input
                    value={formData.phone}
                    onChange={(e) => updateField('phone', e.target.value)}
                    placeholder="03001234567"
                    className="pl-11 h-12 rounded-xl"
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('CNIC', 'شناختی کارڈ نمبر')}</Label>
                <div className="relative">
                  <CreditCard className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                  <Input
                    value={formData.cnic}
                    onChange={(e) => updateField('cnic', e.target.value)}
                    placeholder="12345-1234567-1"
                    className="pl-11 h-12 rounded-xl"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2">
                  <Label className={cn(isUrdu && 'font-urdu')}>{t('City', 'شہر')}</Label>
                  <div className="relative">
                    <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                    <Input
                      value={formData.city}
                      onChange={(e) => updateField('city', e.target.value)}
                      placeholder={t('City', 'شہر')}
                      className="pl-11 h-12 rounded-xl"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label className={cn(isUrdu && 'font-urdu')}>{t('Age', 'عمر')}</Label>
                  <Input
                    type="number"
                    value={formData.age}
                    onChange={(e) => updateField('age', e.target.value)}
                    placeholder="25"
                    className="h-12 rounded-xl"
                    min="18"
                    max="100"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('Gender', 'جنس')}</Label>
                <Select value={formData.gender} onValueChange={(v) => updateField('gender', v)}>
                  <SelectTrigger className="h-12 rounded-xl">
                    <SelectValue placeholder={t('Select gender', 'جنس منتخب کریں')} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="female">{t('Female', 'خاتون')}</SelectItem>
                    <SelectItem value="male">{t('Male', 'مرد')}</SelectItem>
                    <SelectItem value="other">{t('Other', 'دیگر')}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </>
          ) : (
            <>
              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('Password', 'پاس ورڈ')} *</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                  <Input
                    type={showPassword ? 'text' : 'password'}
                    value={formData.password}
                    onChange={(e) => updateField('password', e.target.value)}
                    placeholder="••••••••"
                    className="pl-11 pr-11 h-12 rounded-xl"
                    required
                    minLength={8}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground"
                  >
                    {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                  </button>
                </div>
                <p className={cn('text-xs text-muted-foreground', isUrdu && 'font-urdu')}>
                  {t('Minimum 8 characters', 'کم از کم 8 حروف')}
                </p>
              </div>

              <div className="space-y-2">
                <Label className={cn(isUrdu && 'font-urdu')}>{t('Confirm Password', 'پاس ورڈ دوبارہ')} *</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                  <Input
                    type={showPassword ? 'text' : 'password'}
                    value={formData.confirmPassword}
                    onChange={(e) => updateField('confirmPassword', e.target.value)}
                    placeholder="••••••••"
                    className="pl-11 h-12 rounded-xl"
                    required
                  />
                </div>
              </div>
            </>
          )}

          <Button 
            type="submit" 
            className="w-full h-12 rounded-xl text-base font-semibold gradient-primary hover:opacity-90 transition-opacity mt-6"
            disabled={isLoading}
          >
            {isLoading ? (
              <div className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
            ) : (
              <span className={cn(isUrdu && 'font-urdu')}>
                {step === 1 ? t('Continue', 'جاری رکھیں') : t('Create Account', 'اکاؤنٹ بنائیں')}
              </span>
            )}
          </Button>
        </form>

        <p className={cn(
          'text-center text-muted-foreground mt-6 text-sm',
          isUrdu && 'font-urdu'
        )}>
          {t('Already have an account?', 'پہلے سے اکاؤنٹ ہے؟')}{' '}
          <Link to="/login" className="text-primary font-semibold hover:underline">
            {t('Sign In', 'سائن ان')}
          </Link>
        </p>
      </div>
    </div>
  );
}
