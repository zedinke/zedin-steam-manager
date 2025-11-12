import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  Tab,
  Tabs,
  Link,
  CircularProgress,
  InputAdornment,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions
} from '@mui/material';
import {
  Visibility,
  VisibilityOff,
  Email,
  Lock,
  Person,
  CalendarToday
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { authStore } from '../../stores/authStore';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel({ children, value, index }: TabPanelProps) {
  return (
    <div hidden={value !== index}>
      {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
    </div>
  );
}

interface LoginFormData {
  email: string;
  password: string;
}

interface RegisterFormData {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  passwordConfirm: string;
  birthDate: Date | null;
}

interface VerificationData {
  email: string;
  token: string;
}

const Login: React.FC = () => {
  const navigate = useNavigate();
  const [tabValue, setTabValue] = useState(0);
  const [showPassword, setShowPassword] = useState(false);
  const [showPasswordConfirm, setShowPasswordConfirm] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [showVerification, setShowVerification] = useState(false);
  const [verificationData, setVerificationData] = useState<VerificationData>({ email: '', token: '' });

  const [loginForm, setLoginForm] = useState<LoginFormData>({
    email: '',
    password: ''
  });

  const [registerForm, setRegisterForm] = useState<RegisterFormData>({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    passwordConfirm: '',
    birthDate: null
  });

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
    setError('');
    setSuccess('');
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const formData = new FormData();
      formData.append('username', loginForm.email);
      formData.append('password', loginForm.password);

      const response = await fetch('/api/auth/login', {
        method: 'POST',
        body: formData,
      });

      if (response.ok) {
        const data = await response.json();
        authStore.getState().login(data.access_token, data.user);
        navigate('/dashboard');
      } else {
        const errorData = await response.json();
        setError(errorData.detail || 'Bejelentkezési hiba');
      }
    } catch (error) {
      setError('Hálózati hiba történt');
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // Validation
    if (registerForm.password !== registerForm.passwordConfirm) {
      setError('A jelszavak nem egyeznek');
      setLoading(false);
      return;
    }

    if (!registerForm.birthDate) {
      setError('A születési dátum megadása kötelező');
      setLoading(false);
      return;
    }

    try {
      const response = await fetch('/api/auth/register', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          first_name: registerForm.firstName,
          last_name: registerForm.lastName,
          email: registerForm.email,
          password: registerForm.password,
          password_confirm: registerForm.passwordConfirm,
          birth_date: registerForm.birthDate?.toISOString().split('T')[0]
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setSuccess(data.message);
        
        if (data.requires_verification) {
          setVerificationData({ email: data.email, token: '' });
          setShowVerification(true);
        } else {
          // Auto-login for development
          setTabValue(0);
          setLoginForm({ email: registerForm.email, password: '' });
        }
        
        // Reset form
        setRegisterForm({
          firstName: '',
          lastName: '',
          email: '',
          password: '',
          passwordConfirm: '',
          birthDate: null
        });
      } else {
        const errorData = await response.json();
        setError(errorData.detail || 'Regisztrációs hiba');
      }
    } catch (error) {
      setError('Hálózati hiba történt');
    } finally {
      setLoading(false);
    }
  };

  const handleVerification = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/auth/verify-email', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          token: verificationData.token
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setSuccess(data.message);
        setShowVerification(false);
        setTabValue(0); // Switch to login tab
        setLoginForm({ email: verificationData.email, password: '' });
      } else {
        const errorData = await response.json();
        setError(errorData.detail || 'Megerősítési hiba');
      }
    } catch (error) {
      setError('Hálózati hiba történt');
    } finally {
      setLoading(false);
    }
  };

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns}>
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          padding: 2
        }}
      >
        <Card sx={{ maxWidth: 500, width: '100%' }}>
          <CardContent sx={{ p: 4 }}>
            <Box sx={{ textAlign: 'center', mb: 3 }}>
              <Typography variant="h4" component="h1" gutterBottom>
                🎮 Zedin Steam Manager
              </Typography>
              <Typography variant="body1" color="text.secondary">
                Professional Steam Server Management
              </Typography>
            </Box>

            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}

            {success && (
              <Alert severity="success" sx={{ mb: 2 }}>
                {success}
              </Alert>
            )}

            <Tabs value={tabValue} onChange={handleTabChange} sx={{ mb: 3 }}>
              <Tab label="Bejelentkezés" />
              <Tab label="Regisztráció" />
            </Tabs>

            <TabPanel value={tabValue} index={0}>
              <Box component="form" onSubmit={handleLogin} sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField
                  fullWidth
                  label="Email cím"
                  type="email"
                  value={loginForm.email}
                  onChange={(e) => setLoginForm({ ...loginForm, email: e.target.value })}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <Email />
                      </InputAdornment>
                    ),
                  }}
                  required
                />
                <TextField
                  fullWidth
                  label="Jelszó"
                  type={showPassword ? 'text' : 'password'}
                  value={loginForm.password}
                  onChange={(e) => setLoginForm({ ...loginForm, password: e.target.value })}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <Lock />
                      </InputAdornment>
                    ),
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton
                          onClick={() => setShowPassword(!showPassword)}
                          edge="end"
                        >
                          {showPassword ? <VisibilityOff /> : <Visibility />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                  required
                />
                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  size="large"
                  disabled={loading}
                  sx={{ mt: 2 }}
                >
                  {loading ? <CircularProgress size={24} /> : 'Bejelentkezés'}
                </Button>
                <Box sx={{ textAlign: 'center', mt: 1 }}>
                  <Link href="#" variant="body2">
                    Elfelejtett jelszó?
                  </Link>
                </Box>
              </Box>
            </TabPanel>

            <TabPanel value={tabValue} index={1}>
              <Box component="form" onSubmit={handleRegister} sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  <TextField
                    fullWidth
                    label="Keresztnév"
                    value={registerForm.firstName}
                    onChange={(e) => setRegisterForm({ ...registerForm, firstName: e.target.value })}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <Person />
                        </InputAdornment>
                      ),
                    }}
                    required
                  />
                  <TextField
                    fullWidth
                    label="Vezetéknév"
                    value={registerForm.lastName}
                    onChange={(e) => setRegisterForm({ ...registerForm, lastName: e.target.value })}
                    required
                  />
                </Box>
                <TextField
                  fullWidth
                  label="Email cím"
                  type="email"
                  value={registerForm.email}
                  onChange={(e) => setRegisterForm({ ...registerForm, email: e.target.value })}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <Email />
                      </InputAdornment>
                    ),
                  }}
                  required
                />
                <TextField
                  fullWidth
                  label="Születési dátum"
                  type="date"
                  value={registerForm.birthDate?.toISOString().split('T')[0] || ''}
                  onChange={(e) => setRegisterForm({ 
                    ...registerForm, 
                    birthDate: e.target.value ? new Date(e.target.value) : null 
                  })}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <CalendarToday />
                      </InputAdornment>
                    ),
                  }}
                  InputLabelProps={{ shrink: true }}
                  required
                />
                <TextField
                  fullWidth
                  label="Jelszó"
                  type={showPassword ? 'text' : 'password'}
                  value={registerForm.password}
                  onChange={(e) => setRegisterForm({ ...registerForm, password: e.target.value })}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <Lock />
                      </InputAdornment>
                    ),
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton
                          onClick={() => setShowPassword(!showPassword)}
                          edge="end"
                        >
                          {showPassword ? <VisibilityOff /> : <Visibility />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                  helperText="Min. 8 karakter, nagybetű, kisbetű és szám"
                  required
                />
                <TextField
                  fullWidth
                  label="Jelszó megerősítés"
                  type={showPasswordConfirm ? 'text' : 'password'}
                  value={registerForm.passwordConfirm}
                  onChange={(e) => setRegisterForm({ ...registerForm, passwordConfirm: e.target.value })}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <Lock />
                      </InputAdornment>
                    ),
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton
                          onClick={() => setShowPasswordConfirm(!showPasswordConfirm)}
                          edge="end"
                        >
                          {showPasswordConfirm ? <VisibilityOff /> : <Visibility />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                  required
                />
                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  size="large"
                  disabled={loading}
                  sx={{ mt: 2 }}
                >
                  {loading ? <CircularProgress size={24} /> : 'Regisztráció'}
                </Button>
              </Box>
            </TabPanel>
          </CardContent>
        </Card>

        {/* Email Verification Dialog */}
        <Dialog open={showVerification} onClose={() => setShowVerification(false)} maxWidth="sm" fullWidth>
          <DialogTitle>📧 Email megerősítés</DialogTitle>
          <DialogContent>
            <Typography paragraph>
              Küldtünk egy megerősítő emailt a(z) <strong>{verificationData.email}</strong> címre.
              Add meg a 6 jegyű kódot vagy kattints az emailben található linkre.
            </Typography>
            <TextField
              fullWidth
              label="Megerősítő kód (6 számjegy)"
              value={verificationData.token}
              onChange={(e) => setVerificationData({ ...verificationData, token: e.target.value })}
              inputProps={{ maxLength: 6 }}
              sx={{ mt: 2 }}
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setShowVerification(false)}>
              Mégse
            </Button>
            <Button
              onClick={handleVerification}
              variant="contained"
              disabled={loading || verificationData.token.length !== 6}
            >
              {loading ? <CircularProgress size={20} /> : 'Megerősítés'}
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </LocalizationProvider>
  );
};

export default Login;