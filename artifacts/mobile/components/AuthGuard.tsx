import React from 'react';
import { View, StyleSheet, Text, Pressable } from 'react-native';
import { useAuth } from '@/context/AuthContext';
import { useColors } from '@/hooks/useColors';
import { router } from 'expo-router';

interface AuthGuardProps {
  children: React.ReactNode;
  fallbackMessage?: string;
  requireOwner?: boolean;
}

export function AuthGuard({ children, fallbackMessage = 'Sign in to access this feature', requireOwner = false }: AuthGuardProps) {
  const { user, isLoading } = useAuth();
  const colors = useColors();

  if (isLoading) {
    return <View style={styles.container} />;
  }

  if (!user) {
    return (
      <View style={[styles.container, { backgroundColor: colors.background }]}>
        <View style={styles.content}>
          <Text style={[styles.message, { color: colors.foreground }]}>{fallbackMessage}</Text>
          <Pressable
            style={[styles.button, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
            onPress={() => router.push('/auth/login')}
          >
            <Text style={[styles.buttonText, { color: colors.primaryForeground }]}>Sign In</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  if (requireOwner && user.role !== 'owner') {
    return (
      <View style={[styles.container, { backgroundColor: colors.background }]}>
        <View style={styles.content}>
          <Text style={[styles.message, { color: colors.foreground }]}>This area is for salon owners only.</Text>
        </View>
      </View>
    );
  }

  return <>{children}</>;
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    alignItems: 'center',
    padding: 24,
    gap: 20,
  },
  message: {
    fontSize: 16,
    textAlign: 'center',
    fontFamily: 'Inter_500Medium',
  },
  button: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonText: {
    fontSize: 16,
    fontFamily: 'Inter_600SemiBold',
  },
});