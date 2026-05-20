import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, Pressable, ScrollView, Platform } from 'react-native';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRegister, RegisterInputRole } from '@workspace/api-client-react';
import { useAuth } from '@/context/AuthContext';
import { useColors } from '@/hooks/useColors';
import { Feather } from '@expo/vector-icons';
import { KeyboardAwareScrollViewCompat } from '@/components/KeyboardAwareScrollViewCompat';

export default function RegisterScreen() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<RegisterInputRole>('user');
  const [error, setError] = useState('');
  
  const { login } = useAuth();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const registerMutation = useRegister();

  const handleRegister = async () => {
    if (!name || !email || !password) {
      setError('Please fill in all required fields');
      return;
    }

    try {
      setError('');
      const response = await registerMutation.mutateAsync({
        data: { name, email, password, role }
      });
      await login(response.token, response.user);
      router.replace('/');
    } catch (err: any) {
      setError(err?.message || 'Registration failed. Please try again.');
    }
  };

  return (
    <KeyboardAwareScrollViewCompat
      style={[styles.container, { backgroundColor: colors.background }]}
      contentContainerStyle={{
        paddingTop: insets.top + 40,
        paddingBottom: insets.bottom + 24,
        paddingHorizontal: 24,
      }}
      bottomOffset={20}
    >
      <View style={styles.header}>
        <View style={styles.logoContainer}>
          <Feather name="scissors" size={32} color={colors.primary} />
          <Text style={[styles.logoText, { color: colors.primary }]}>GlowBook</Text>
        </View>
        <Text style={[styles.title, { color: colors.foreground }]}>Create an account</Text>
        <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
          Join the premium salon network
        </Text>
      </View>

      <View style={styles.form}>
        {error ? (
          <View style={[styles.errorContainer, { backgroundColor: '#4f0f0f' }]}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        ) : null}

        <View style={styles.inputGroup}>
          <Text style={[styles.label, { color: colors.foreground }]}>Full Name</Text>
          <TextInput
            style={[
              styles.input,
              {
                backgroundColor: colors.input,
                color: colors.foreground,
                borderColor: colors.border,
                borderRadius: colors.radius,
              },
            ]}
            placeholder="John Doe"
            placeholderTextColor={colors.mutedForeground}
            value={name}
            onChangeText={setName}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={[styles.label, { color: colors.foreground }]}>Email</Text>
          <TextInput
            style={[
              styles.input,
              {
                backgroundColor: colors.input,
                color: colors.foreground,
                borderColor: colors.border,
                borderRadius: colors.radius,
              },
            ]}
            placeholder="your@email.com"
            placeholderTextColor={colors.mutedForeground}
            keyboardType="email-address"
            autoCapitalize="none"
            value={email}
            onChangeText={setEmail}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={[styles.label, { color: colors.foreground }]}>Password</Text>
          <TextInput
            style={[
              styles.input,
              {
                backgroundColor: colors.input,
                color: colors.foreground,
                borderColor: colors.border,
                borderRadius: colors.radius,
              },
            ]}
            placeholder="Minimum 6 characters"
            placeholderTextColor={colors.mutedForeground}
            secureTextEntry
            value={password}
            onChangeText={setPassword}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={[styles.label, { color: colors.foreground }]}>Account Type</Text>
          <View style={styles.roleSelector}>
            <Pressable
              style={[
                styles.roleOption,
                {
                  backgroundColor: role === 'user' ? colors.primary : colors.card,
                  borderColor: role === 'user' ? colors.primary : colors.border,
                  borderTopLeftRadius: colors.radius,
                  borderBottomLeftRadius: colors.radius,
                },
              ]}
              onPress={() => setRole('user')}
            >
              <Text
                style={[
                  styles.roleText,
                  { color: role === 'user' ? colors.primaryForeground : colors.foreground },
                ]}
              >
                Customer
              </Text>
            </Pressable>
            <Pressable
              style={[
                styles.roleOption,
                {
                  backgroundColor: role === 'owner' ? colors.primary : colors.card,
                  borderColor: role === 'owner' ? colors.primary : colors.border,
                  borderTopRightRadius: colors.radius,
                  borderBottomRightRadius: colors.radius,
                },
              ]}
              onPress={() => setRole('owner')}
            >
              <Text
                style={[
                  styles.roleText,
                  { color: role === 'owner' ? colors.primaryForeground : colors.foreground },
                ]}
              >
                Salon Owner
              </Text>
            </Pressable>
          </View>
        </View>

        <Pressable
          style={[
            styles.button,
            { backgroundColor: colors.primary, borderRadius: colors.radius },
            registerMutation.isPending && { opacity: 0.7 },
          ]}
          onPress={handleRegister}
          disabled={registerMutation.isPending}
        >
          <Text style={[styles.buttonText, { color: colors.primaryForeground }]}>
            {registerMutation.isPending ? 'Creating account...' : 'Create Account'}
          </Text>
        </Pressable>
      </View>

      <View style={styles.footer}>
        <Text style={[styles.footerText, { color: colors.mutedForeground }]}>
          Already have an account?{' '}
        </Text>
        <Pressable onPress={() => router.push('/auth/login')}>
          <Text style={[styles.link, { color: colors.primary }]}>Sign In</Text>
        </Pressable>
      </View>
    </KeyboardAwareScrollViewCompat>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    marginBottom: 32,
  },
  logoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 24,
  },
  logoText: {
    fontSize: 24,
    fontFamily: 'Inter_700Bold',
  },
  title: {
    fontSize: 32,
    fontFamily: 'Inter_700Bold',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    fontFamily: 'Inter_400Regular',
  },
  form: {
    gap: 20,
  },
  errorContainer: {
    padding: 12,
    borderRadius: 8,
  },
  errorText: {
    color: '#ef4444',
    fontSize: 14,
    fontFamily: 'Inter_500Medium',
  },
  inputGroup: {
    gap: 8,
  },
  label: {
    fontSize: 14,
    fontFamily: 'Inter_500Medium',
  },
  input: {
    height: 52,
    borderWidth: 1,
    paddingHorizontal: 16,
    fontSize: 16,
    fontFamily: 'Inter_400Regular',
  },
  roleSelector: {
    flexDirection: 'row',
    height: 48,
  },
  roleOption: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  roleText: {
    fontSize: 14,
    fontFamily: 'Inter_600SemiBold',
  },
  button: {
    height: 52,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 12,
  },
  buttonText: {
    fontSize: 16,
    fontFamily: 'Inter_600SemiBold',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 48,
  },
  footerText: {
    fontSize: 14,
    fontFamily: 'Inter_400Regular',
  },
  link: {
    fontSize: 14,
    fontFamily: 'Inter_600SemiBold',
  },
});