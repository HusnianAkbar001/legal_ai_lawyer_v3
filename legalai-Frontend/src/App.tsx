import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import { LanguageProvider } from "@/contexts/LanguageContext";
import { BottomNav } from "@/components/BottomNav";
import HomePage from "./pages/HomePage";
import LoginPage from "./pages/LoginPage";
import SignupPage from "./pages/SignupPage";
import ForgotPasswordPage from "./pages/ForgotPasswordPage";
import ChatPage from "./pages/ChatPage";
import BrowsePage from "./pages/BrowsePage";
import DraftsPage from "./pages/DraftsPage";
import TemplateDetailPage from "./pages/TemplateDetailPage";
import RemindersPage from "./pages/RemindersPage";
import ProfilePage from "./pages/ProfilePage";
import LawyersPage from "./pages/LawyersPage";
import SupportPage from "./pages/SupportPage";
import BookmarksPage from "./pages/BookmarksPage";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <LanguageProvider>
      <AuthProvider>
        <TooltipProvider>
          <Toaster />
          <Sonner />
          <BrowserRouter>
            <Routes>
              <Route path="/" element={<><HomePage /><BottomNav /></>} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/signup" element={<SignupPage />} />
              <Route path="/forgot-password" element={<ForgotPasswordPage />} />
              <Route path="/chat" element={<><ChatPage /><BottomNav /></>} />
              <Route path="/browse" element={<><BrowsePage /><BottomNav /></>} />
              <Route path="/browse/:category" element={<><BrowsePage /><BottomNav /></>} />
              <Route path="/drafts" element={<><DraftsPage /><BottomNav /></>} />
              <Route path="/templates" element={<><DraftsPage /><BottomNav /></>} />
              <Route path="/templates/:templateId" element={<><TemplateDetailPage /><BottomNav /></>} />
              <Route path="/reminders" element={<><RemindersPage /><BottomNav /></>} />
              <Route path="/profile" element={<><ProfilePage /><BottomNav /></>} />
              <Route path="/lawyers" element={<><LawyersPage /><BottomNav /></>} />
              <Route path="/support" element={<><SupportPage /><BottomNav /></>} />
              <Route path="/bookmarks" element={<><BookmarksPage /><BottomNav /></>} />
              <Route path="*" element={<NotFound />} />
            </Routes>
          </BrowserRouter>
        </TooltipProvider>
      </AuthProvider>
    </LanguageProvider>
  </QueryClientProvider>
);

export default App;
