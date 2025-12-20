import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useLanguage } from '@/contexts/LanguageContext';
import { api } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { 
  User, Settings, LogOut, ChevronRight, Bell, Shield, Globe, 
  Moon, Sun, Lock, Edit, Camera, Loader2 
} from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';

export default function ProfilePage() {
  const { user, isAuthenticated, logout, refreshUser } = useAuth();
  const { t, isUrdu, language, setLanguage } = useLanguage();
  const { toast } = useToast();
  const navigate = useNavigate();

  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState({
    name: user?.name || '',
    phone: user?.phone || '',
    city: user?.city || '',
  });
  const [isSaving, setIsSaving] = useState(false);

  const [passwordData, setPasswordData] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });
  const [isPasswordDialogOpen, setIsPasswordDialogOpen] = useState(false);
  const [isChangingPassword, setIsChangingPassword] = useState(false);

  const handleLogout = () => {
    logout();
    toast({
      title: t('Logged out', 'لاگ آؤٹ ہو گئے'),
    });
    navigate('/');
  };

  const handleSaveProfile = async () => {
    setIsSaving(true);
    const response = await api.updateMe(editData);
    if (response.error) {
      toast({
        title: t('Error', 'خرابی'),
        description: response.error,
        variant: 'destructive',
      });
    } else {
      toast({
        title: t('Profile updated', 'پروفائل اپڈیٹ ہو گئی'),
      });
      await refreshUser();
      setIsEditing(false);
    }
    setIsSaving(false);
  };

  const handleChangePassword = async () => {
    if (passwordData.newPassword !== passwordData.confirmPassword) {
      toast({
        title: t('Password mismatch', 'پاس ورڈ مختلف ہیں'),
        variant: 'destructive',
      });
      return;
    }

    setIsChangingPassword(true);
    const response = await api.changePassword(
      passwordData.currentPassword,
      passwordData.newPassword,
      passwordData.confirmPassword
    );

    if (response.error) {
      toast({
        title: t('Error', 'خرابی'),
        description: response.error,
        variant: 'destructive',
      });
    } else {
      toast({
        title: t('Password changed', 'پاس ورڈ بدل گیا'),
      });
      setIsPasswordDialogOpen(false);
      setPasswordData({ currentPassword: '', newPassword: '', confirmPassword: '' });
    }
    setIsChangingPassword(false);
  };

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center p-4">
        <User className="h-16 w-16 text-muted-foreground/50 mb-4" />
        <h2 className={cn('text-xl font-bold text-foreground mb-2', isUrdu && 'font-urdu')}>
          {t('Welcome to Legal Awareness', 'قانونی آگاہی میں خوش آمدید')}
        </h2>
        <p className={cn('text-muted-foreground text-center mb-6', isUrdu && 'font-urdu')}>
          {t('Login or create an account to access all features', 'تمام خصوصیات تک رسائی کے لیے لاگ ان کریں')}
        </p>
        <div className="flex gap-3">
          <Button onClick={() => navigate('/login')} variant="outline">
            {t('Login', 'لاگ ان')}
          </Button>
          <Button onClick={() => navigate('/signup')} className="gradient-primary">
            {t('Sign Up', 'سائن اپ')}
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Profile Header */}
      <div className="gradient-primary px-4 pt-8 pb-12 rounded-b-3xl">
        <div className="flex items-center gap-4">
          <div className="relative">
            <div className="w-20 h-20 rounded-full bg-white/20 flex items-center justify-center text-primary-foreground text-2xl font-bold">
              {user?.name?.charAt(0).toUpperCase()}
            </div>
          </div>
          <div className="flex-1 text-primary-foreground">
            <h1 className={cn('text-xl font-bold', isUrdu && 'font-urdu')}>
              {user?.name}
            </h1>
            <p className="text-sm opacity-90">{user?.email}</p>
          </div>
          <Button
            variant="ghost"
            size="icon"
            onClick={() => {
              setEditData({
                name: user?.name || '',
                phone: user?.phone || '',
                city: user?.city || '',
              });
              setIsEditing(true);
            }}
            className="text-primary-foreground hover:bg-white/10"
          >
            <Edit className="h-5 w-5" />
          </Button>
        </div>
      </div>

      <div className="px-4 -mt-6 space-y-4">
        {/* Quick Stats */}
        <div className="bg-card rounded-xl p-4 shadow-md border border-border/50 grid grid-cols-3 gap-4 text-center">
          <div>
            <p className="text-2xl font-bold text-primary">0</p>
            <p className={cn('text-xs text-muted-foreground', isUrdu && 'font-urdu')}>
              {t('Chats', 'چیٹس')}
            </p>
          </div>
          <div>
            <p className="text-2xl font-bold text-primary">0</p>
            <p className={cn('text-xs text-muted-foreground', isUrdu && 'font-urdu')}>
              {t('Drafts', 'دستاویزات')}
            </p>
          </div>
          <div>
            <p className="text-2xl font-bold text-primary">0</p>
            <p className={cn('text-xs text-muted-foreground', isUrdu && 'font-urdu')}>
              {t('Bookmarks', 'بک مارکس')}
            </p>
          </div>
        </div>

        {/* Settings */}
        <div className="bg-card rounded-xl border border-border/50 overflow-hidden">
          <h2 className={cn('text-sm font-semibold text-muted-foreground px-4 py-3 bg-muted/50', isUrdu && 'font-urdu text-right')}>
            {t('Settings', 'سیٹنگز')}
          </h2>

          {/* Language Toggle */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-border/50">
            <div className={cn('flex items-center gap-3', isUrdu && 'flex-row-reverse')}>
              <Globe className="h-5 w-5 text-muted-foreground" />
              <span className={cn('text-foreground', isUrdu && 'font-urdu')}>
                {t('Language', 'زبان')}
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-sm text-muted-foreground">EN</span>
              <Switch
                checked={language === 'ur'}
                onCheckedChange={(checked) => setLanguage(checked ? 'ur' : 'en')}
              />
              <span className="text-sm text-muted-foreground font-urdu">اردو</span>
            </div>
          </div>

          {/* Reminders */}
          <Link to="/reminders" className="flex items-center justify-between px-4 py-3 border-b border-border/50 hover:bg-muted/50 transition-colors">
            <div className={cn('flex items-center gap-3', isUrdu && 'flex-row-reverse')}>
              <Bell className="h-5 w-5 text-muted-foreground" />
              <span className={cn('text-foreground', isUrdu && 'font-urdu')}>
                {t('Reminders', 'یاد دہانیاں')}
              </span>
            </div>
            <ChevronRight className="h-5 w-5 text-muted-foreground" />
          </Link>

          {/* Change Password */}
          <Dialog open={isPasswordDialogOpen} onOpenChange={setIsPasswordDialogOpen}>
            <DialogTrigger asChild>
              <button className="w-full flex items-center justify-between px-4 py-3 border-b border-border/50 hover:bg-muted/50 transition-colors">
                <div className={cn('flex items-center gap-3', isUrdu && 'flex-row-reverse')}>
                  <Lock className="h-5 w-5 text-muted-foreground" />
                  <span className={cn('text-foreground', isUrdu && 'font-urdu')}>
                    {t('Change Password', 'پاس ورڈ بدلیں')}
                  </span>
                </div>
                <ChevronRight className="h-5 w-5 text-muted-foreground" />
              </button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle className={cn(isUrdu && 'font-urdu text-right')}>
                  {t('Change Password', 'پاس ورڈ بدلیں')}
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-4 mt-4">
                <div className="space-y-2">
                  <Label>{t('Current Password', 'موجودہ پاس ورڈ')}</Label>
                  <Input
                    type="password"
                    value={passwordData.currentPassword}
                    onChange={(e) => setPasswordData(prev => ({ ...prev, currentPassword: e.target.value }))}
                  />
                </div>
                <div className="space-y-2">
                  <Label>{t('New Password', 'نیا پاس ورڈ')}</Label>
                  <Input
                    type="password"
                    value={passwordData.newPassword}
                    onChange={(e) => setPasswordData(prev => ({ ...prev, newPassword: e.target.value }))}
                  />
                </div>
                <div className="space-y-2">
                  <Label>{t('Confirm Password', 'پاس ورڈ دوبارہ')}</Label>
                  <Input
                    type="password"
                    value={passwordData.confirmPassword}
                    onChange={(e) => setPasswordData(prev => ({ ...prev, confirmPassword: e.target.value }))}
                  />
                </div>
                <Button onClick={handleChangePassword} disabled={isChangingPassword} className="w-full">
                  {isChangingPassword ? <Loader2 className="h-4 w-4 animate-spin" /> : t('Update Password', 'پاس ورڈ اپڈیٹ کریں')}
                </Button>
              </div>
            </DialogContent>
          </Dialog>

          {/* Privacy */}
          <div className="flex items-center justify-between px-4 py-3">
            <div className={cn('flex items-center gap-3', isUrdu && 'flex-row-reverse')}>
              <Shield className="h-5 w-5 text-muted-foreground" />
              <span className={cn('text-foreground', isUrdu && 'font-urdu')}>
                {t('Privacy Mode', 'نجی موڈ')}
              </span>
            </div>
            <Switch
              checked={api.getSafeMode()}
              onCheckedChange={(checked) => api.setSafeMode(checked)}
            />
          </div>
        </div>

        {/* Logout */}
        <Button
          variant="outline"
          onClick={handleLogout}
          className="w-full text-destructive hover:text-destructive hover:bg-destructive/10 border-destructive/30"
        >
          <LogOut className="h-5 w-5 mr-2" />
          {t('Logout', 'لاگ آؤٹ')}
        </Button>
      </div>

      {/* Edit Profile Dialog */}
      <Dialog open={isEditing} onOpenChange={setIsEditing}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className={cn(isUrdu && 'font-urdu text-right')}>
              {t('Edit Profile', 'پروفائل ترمیم')}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 mt-4">
            <div className="space-y-2">
              <Label>{t('Name', 'نام')}</Label>
              <Input
                value={editData.name}
                onChange={(e) => setEditData(prev => ({ ...prev, name: e.target.value }))}
              />
            </div>
            <div className="space-y-2">
              <Label>{t('Phone', 'فون')}</Label>
              <Input
                value={editData.phone}
                onChange={(e) => setEditData(prev => ({ ...prev, phone: e.target.value }))}
              />
            </div>
            <div className="space-y-2">
              <Label>{t('City', 'شہر')}</Label>
              <Input
                value={editData.city}
                onChange={(e) => setEditData(prev => ({ ...prev, city: e.target.value }))}
              />
            </div>
            <Button onClick={handleSaveProfile} disabled={isSaving} className="w-full gradient-primary">
              {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : t('Save Changes', 'تبدیلیاں محفوظ کریں')}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
