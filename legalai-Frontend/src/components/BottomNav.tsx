import { Home, MessageCircle, BookOpen, FileText, Bell, User, Shield, Eye, EyeOff } from 'lucide-react';
import { Link, useLocation } from 'react-router-dom';
import { cn } from '@/lib/utils';
import { useLanguage } from '@/contexts/LanguageContext';
import { api } from '@/lib/api';
import { useState, useEffect } from 'react';
import { Switch } from '@/components/ui/switch';

const navItems = [
  { path: '/', icon: Home, labelEn: 'Home', labelUr: 'ہوم' },
  { path: '/chat', icon: MessageCircle, labelEn: 'Chat', labelUr: 'چیٹ' },
  { path: '/browse', icon: BookOpen, labelEn: 'Browse', labelUr: 'براؤز' },
  { path: '/drafts', icon: FileText, labelEn: 'Drafts', labelUr: 'دستاویزات' },
  { path: '/profile', icon: User, labelEn: 'Profile', labelUr: 'پروفائل' },
];

export function BottomNav() {
  const location = useLocation();
  const { t, isUrdu } = useLanguage();
  const [safeMode, setSafeMode] = useState(api.getSafeMode());

  const toggleSafeMode = () => {
    const newValue = !safeMode;
    setSafeMode(newValue);
    api.setSafeMode(newValue);
  };

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-card/95 backdrop-blur-lg border-t border-border shadow-lg">
      <div className="flex items-center justify-between px-1" style={{ paddingBottom: 'var(--safe-area-inset-bottom, 0px)' }}>
        <div className="flex items-center justify-around flex-1">
          {navItems.map((item) => {
            const isActive = location.pathname === item.path;
            const Icon = item.icon;
            
            return (
              <Link
                key={item.path}
                to={item.path}
                className={cn(
                  'flex flex-col items-center py-2 px-3 transition-all duration-200',
                  isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary/80'
                )}
              >
                <Icon className={cn('h-5 w-5 mb-1', isActive && 'scale-110')} />
                <span className={cn('text-xs font-medium', isUrdu && 'font-urdu')}>
                  {t(item.labelEn, item.labelUr)}
                </span>
                {isActive && (
                  <div className="absolute bottom-0 w-12 h-0.5 bg-primary rounded-t-full" />
                )}
              </Link>
            );
          })}
        </div>
        
        {/* Safe Mode Toggle */}
        <div className="flex flex-col items-center py-2 px-2 border-l border-border">
          <button 
            onClick={toggleSafeMode}
            className={cn(
              'p-1.5 rounded-full transition-all',
              safeMode ? 'bg-primary/20 text-primary' : 'text-muted-foreground'
            )}
          >
            {safeMode ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
          </button>
          <span className={cn('text-[10px] mt-0.5', isUrdu && 'font-urdu')}>
            {t('Private', 'نجی')}
          </span>
        </div>
      </div>
    </nav>
  );
}
