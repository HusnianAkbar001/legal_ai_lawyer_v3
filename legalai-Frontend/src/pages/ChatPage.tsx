import { useState, useRef, useEffect } from 'react';
import { api } from '@/lib/api';
import { useLanguage } from '@/contexts/LanguageContext';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Send, Plus, MessageCircle, Loader2, Shield, Bot, User as UserIcon, Menu, Trash2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { Message, Conversation } from '@/lib/types';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet';
import { ScrollArea } from '@/components/ui/scroll-area';

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
}

export default function ChatPage() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [conversationId, setConversationId] = useState<number | undefined>();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [showHistory, setShowHistory] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const { t, isUrdu, language } = useLanguage();
  const { isAuthenticated } = useAuth();
  const { toast } = useToast();

  useEffect(() => {
    if (isAuthenticated) {
      loadConversations();
    }
  }, [isAuthenticated]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const loadConversations = async () => {
    const response = await api.getConversations();
    if (response.data) {
      setConversations((response.data as any).conversations || response.data as Conversation[] || []);
    }
  };

  const loadConversation = async (convId: number) => {
    const response = await api.getConversationMessages(convId);
    if (response.data) {
      const msgs = ((response.data as any).messages || response.data as Message[] || []).map((m: Message) => ({
        id: String(m.id),
        role: m.role,
        content: m.content,
      }));
      setMessages(msgs);
      setConversationId(convId);
      setShowHistory(false);
    }
  };

  const startNewChat = () => {
    setMessages([]);
    setConversationId(undefined);
    setShowHistory(false);
  };

  const deleteConversation = async (convId: number) => {
    await api.deleteConversation(convId);
    loadConversations();
    if (conversationId === convId) {
      startNewChat();
    }
  };

  const handleSend = async () => {
    if (!input.trim() || isLoading) return;

    if (!isAuthenticated) {
      toast({
        title: t('Login required', 'لاگ ان ضروری ہے'),
        description: t('Please login to use the chat.', 'چیٹ استعمال کرنے کے لیے لاگ ان کریں۔'),
        variant: 'destructive',
      });
      return;
    }

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: input,
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      const response = await api.sendMessage(input, language, conversationId);
      
      if (response.data) {
        const data = response.data as any;
        const aiMessage: ChatMessage = {
          id: (Date.now() + 1).toString(),
          role: 'assistant',
          content: data.answer || data.content || data.message || 'No response',
        };
        setMessages(prev => [...prev, aiMessage]);
        
        if (!conversationId && data.conversationId) {
          setConversationId(data.conversationId);
          loadConversations();
        }
      } else {
        throw new Error(response.error || 'Failed to get response');
      }
    } catch (error) {
      toast({
        title: t('Error', 'خرابی'),
        description: t('Failed to send message. Please try again.', 'پیغام بھیجنے میں ناکامی۔ دوبارہ کوشش کریں۔'),
        variant: 'destructive',
      });
    }

    setIsLoading(false);
  };

  return (
    <div className="flex flex-col h-screen bg-background">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-border bg-card/80 backdrop-blur-sm">
        <Sheet open={showHistory} onOpenChange={setShowHistory}>
          <SheetTrigger asChild>
            <Button variant="ghost" size="icon" className="text-muted-foreground">
              <Menu className="h-5 w-5" />
            </Button>
          </SheetTrigger>
          <SheetContent side="left" className="w-80 p-0">
            <SheetHeader className="p-4 border-b">
              <SheetTitle className={cn(isUrdu && 'font-urdu text-right')}>
                {t('Chat History', 'چیٹ تاریخ')}
              </SheetTitle>
            </SheetHeader>
            <ScrollArea className="h-[calc(100vh-80px)]">
              <div className="p-2 space-y-1">
                <Button
                  onClick={startNewChat}
                  variant="outline"
                  className="w-full justify-start gap-2 mb-2"
                >
                  <Plus className="h-4 w-4" />
                  <span className={cn(isUrdu && 'font-urdu')}>{t('New Chat', 'نئی چیٹ')}</span>
                </Button>
                
                {conversations.map((conv) => (
                  <div
                    key={conv.id}
                    className={cn(
                      'flex items-center gap-2 p-2 rounded-lg cursor-pointer hover:bg-muted transition-colors group',
                      conversationId === conv.id && 'bg-primary/10'
                    )}
                  >
                    <button
                      onClick={() => loadConversation(conv.id)}
                      className="flex-1 text-left"
                    >
                      <MessageCircle className="h-4 w-4 text-muted-foreground inline mr-2" />
                      <span className="text-sm truncate">{conv.title || t('Untitled', 'بے نام')}</span>
                    </button>
                    <button
                      onClick={() => deleteConversation(conv.id)}
                      className="opacity-0 group-hover:opacity-100 p-1 hover:text-destructive transition-all"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}
              </div>
            </ScrollArea>
          </SheetContent>
        </Sheet>

        <div className={cn('flex-1 text-center', isUrdu && 'font-urdu')}>
          <h1 className="font-semibold text-foreground">
            {t('Legal Assistant', 'قانونی معاون')}
          </h1>
          <p className="text-xs text-muted-foreground">
            {t('AI-powered guidance', 'AI سے رہنمائی')}
          </p>
        </div>

        <Button variant="ghost" size="icon" onClick={startNewChat} className="text-muted-foreground">
          <Plus className="h-5 w-5" />
        </Button>
      </div>

      {/* Messages */}
      <ScrollArea className="flex-1 px-4 py-4">
        {messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-center px-6">
            <div className="p-4 rounded-full bg-primary/10 mb-4">
              <Bot className="h-10 w-10 text-primary" />
            </div>
            <h2 className={cn('text-lg font-semibold text-foreground mb-2', isUrdu && 'font-urdu')}>
              {t('How can I help you?', 'میں آپ کی کیسے مدد کر سکتی ہوں؟')}
            </h2>
            <p className={cn('text-sm text-muted-foreground mb-6 max-w-xs', isUrdu && 'font-urdu')}>
              {t(
                'Ask me about your legal rights, workplace issues, domestic matters, or any legal concerns.',
                'مجھ سے اپنے قانونی حقوق، دفتری مسائل، گھریلو معاملات، یا کسی بھی قانونی تشویش کے بارے میں پوچھیں۔'
              )}
            </p>
            <div className="flex flex-wrap gap-2 justify-center">
              {[
                { en: 'Workplace harassment', ur: 'دفتری ہراسانی' },
                { en: 'Domestic violence', ur: 'گھریلو تشدد' },
                { en: 'Divorce process', ur: 'طلاق کا طریقہ' },
              ].map((suggestion) => (
                <button
                  key={suggestion.en}
                  onClick={() => setInput(isUrdu ? suggestion.ur : suggestion.en)}
                  className={cn(
                    'px-3 py-2 text-sm bg-secondary rounded-full hover:bg-secondary/80 transition-colors',
                    isUrdu && 'font-urdu'
                  )}
                >
                  {isUrdu ? suggestion.ur : suggestion.en}
                </button>
              ))}
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            {messages.map((message) => (
              <div
                key={message.id}
                className={cn(
                  'flex gap-3 message-enter',
                  message.role === 'user' ? 'flex-row-reverse' : ''
                )}
              >
                <div className={cn(
                  'p-2 rounded-full h-8 w-8 flex items-center justify-center flex-shrink-0',
                  message.role === 'user' ? 'bg-primary' : 'bg-muted'
                )}>
                  {message.role === 'user' ? (
                    <UserIcon className="h-4 w-4 text-primary-foreground" />
                  ) : (
                    <Bot className="h-4 w-4 text-muted-foreground" />
                  )}
                </div>
                <div className={cn(
                  'rounded-2xl px-4 py-3 max-w-[80%]',
                  message.role === 'user' 
                    ? 'bg-primary text-primary-foreground rounded-tr-sm' 
                    : 'bg-muted text-foreground rounded-tl-sm',
                  isUrdu && 'font-urdu text-right'
                )}>
                  <p className="text-sm whitespace-pre-wrap">{message.content}</p>
                </div>
              </div>
            ))}
            
            {isLoading && (
              <div className="flex gap-3 message-enter">
                <div className="p-2 rounded-full h-8 w-8 flex items-center justify-center bg-muted">
                  <Bot className="h-4 w-4 text-muted-foreground" />
                </div>
                <div className="bg-muted rounded-2xl rounded-tl-sm px-4 py-3">
                  <div className="flex gap-1">
                    <span className="w-2 h-2 bg-muted-foreground/50 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                    <span className="w-2 h-2 bg-muted-foreground/50 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                    <span className="w-2 h-2 bg-muted-foreground/50 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                  </div>
                </div>
              </div>
            )}
            
            <div ref={messagesEndRef} />
          </div>
        )}
      </ScrollArea>

      {/* Disclaimer */}
      <div className="px-4 py-2 bg-warning/5 border-t border-warning/20">
        <div className="flex items-center gap-2 text-xs text-warning-foreground">
          <Shield className="h-3 w-3 flex-shrink-0" />
          <p className={cn(isUrdu && 'font-urdu')}>
            {t('For awareness only. Consult a lawyer for legal advice.', 'صرف آگاہی کے لیے۔ قانونی مشورے کے لیے وکیل سے رابطہ کریں۔')}
          </p>
        </div>
      </div>

      {/* Input */}
      <div className="p-4 pb-24 bg-card border-t border-border">
        <div className="flex gap-2">
          <Input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
            placeholder={t('Type your legal question...', 'اپنا قانونی سوال لکھیں...')}
            className={cn('h-12 rounded-xl pr-12', isUrdu && 'font-urdu text-right')}
            disabled={isLoading}
          />
          <Button
            onClick={handleSend}
            disabled={!input.trim() || isLoading}
            className="h-12 w-12 rounded-xl gradient-primary"
          >
            {isLoading ? (
              <Loader2 className="h-5 w-5 animate-spin" />
            ) : (
              <Send className="h-5 w-5" />
            )}
          </Button>
        </div>
      </div>
    </div>
  );
}
