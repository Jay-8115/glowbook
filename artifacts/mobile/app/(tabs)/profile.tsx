import React, { useState } from 'react';
import {
  StyleSheet, View, Text, TouchableOpacity, ScrollView, Platform,
  TextInput,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather, Ionicons } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import { useAuth } from '@/context/AuthContext';
import { useUpdateProfile, getGetMeQueryKey } from '@workspace/api-client-react';
import { useQueryClient } from '@tanstack/react-query';
import { router } from 'expo-router';
import * as Haptics from 'expo-haptics';

function MenuItem({ icon, label, onPress, danger }: { icon: string; label: string; onPress: () => void; danger?: boolean }) {
  const colors = useColors();
  return (
    <TouchableOpacity
      style={[styles.menuItem, { borderBottomColor: colors.border }]}
      onPress={onPress}
      activeOpacity={0.7}
    >
      <View style={[styles.menuIcon, { backgroundColor: danger ? '#ef444420' : colors.secondary }]}>
        <Feather name={icon as any} size={18} color={danger ? '#ef4444' : colors.foreground} />
      </View>
      <Text style={[styles.menuLabel, { color: danger ? '#ef4444' : colors.foreground }]}>{label}</Text>
      {!danger && <Feather name="chevron-right" size={18} color={colors.mutedForeground} />}
    </TouchableOpacity>
  );
}

export default function ProfileScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { user, logout, isOwner } = useAuth();
  const queryClient = useQueryClient();
  const updateProfile = useUpdateProfile();

  const [editing, setEditing] = useState(false);
  const [name, setName] = useState(user?.name ?? '');
  const [phone, setPhone] = useState(user?.phone ?? '');

  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;
  const bottomInset = Platform.OS === 'web' ? 34 + 84 : insets.bottom + 84;

  const handleSave = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    await updateProfile.mutateAsync({ data: { name, phone: phone || null } });
    queryClient.invalidateQueries({ queryKey: getGetMeQueryKey() });
    setEditing(false);
  };

  const handleLogout = () => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
    logout();
  };

  const initials = (user?.name ?? 'U').split(' ').map((n) => n[0]).join('').toUpperCase().slice(0, 2);

  if (!user) {
    return (
      <View style={[styles.centered, { backgroundColor: colors.background, paddingTop: topInset }]}>
        <View style={[styles.avatar, { backgroundColor: colors.primary + '30' }]}>
          <Feather name="user" size={40} color={colors.primary} />
        </View>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>GlowBook</Text>
        <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
          Sign in to manage your bookings and save your favorite salons
        </Text>
        <TouchableOpacity
          style={[styles.signInBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
          onPress={() => router.push('/auth/login')}
        >
          <Text style={[styles.signInBtnText, { color: colors.primaryForeground }]}>Sign In</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={() => router.push('/auth/register')}>
          <Text style={[styles.registerLink, { color: colors.primary }]}>Create an account</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: colors.background }]}
      contentContainerStyle={{ paddingBottom: bottomInset }}
      showsVerticalScrollIndicator={false}
    >
      {/* Profile Header */}
      <View style={[styles.profileHeader, { paddingTop: topInset, backgroundColor: colors.card }]}>
        <View style={[styles.avatar, { backgroundColor: colors.primary }]}>
          <Text style={[styles.initials, { color: colors.primaryForeground }]}>{initials}</Text>
        </View>
        {editing ? (
          <View style={styles.editFields}>
            <TextInput
              style={[styles.editInput, { color: colors.foreground, backgroundColor: colors.input, borderColor: colors.border, borderRadius: 8 }]}
              value={name}
              onChangeText={setName}
              placeholder="Your name"
              placeholderTextColor={colors.mutedForeground}
            />
            <TextInput
              style={[styles.editInput, { color: colors.foreground, backgroundColor: colors.input, borderColor: colors.border, borderRadius: 8 }]}
              value={phone}
              onChangeText={setPhone}
              placeholder="Phone number"
              placeholderTextColor={colors.mutedForeground}
              keyboardType="phone-pad"
            />
            <View style={styles.editActions}>
              <TouchableOpacity
                style={[styles.editBtn, { backgroundColor: colors.muted, borderRadius: 8 }]}
                onPress={() => setEditing(false)}
              >
                <Text style={[styles.editBtnText, { color: colors.foreground }]}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.editBtn, { backgroundColor: colors.primary, borderRadius: 8 }]}
                onPress={handleSave}
              >
                <Text style={[styles.editBtnText, { color: colors.primaryForeground }]}>Save</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          <>
            <Text style={[styles.userName, { color: colors.foreground }]}>{user.name}</Text>
            <Text style={[styles.userEmail, { color: colors.mutedForeground }]}>{user.email}</Text>
            {user.role === 'owner' && (
              <View style={[styles.roleBadge, { backgroundColor: colors.primary + '20' }]}>
                <Text style={[styles.roleText, { color: colors.primary }]}>Salon Owner</Text>
              </View>
            )}
            <TouchableOpacity
              style={[styles.editProfileBtn, { borderColor: colors.border, borderRadius: 8 }]}
              onPress={() => setEditing(true)}
            >
              <Feather name="edit-2" size={14} color={colors.mutedForeground} />
              <Text style={[styles.editProfileText, { color: colors.mutedForeground }]}>Edit Profile</Text>
            </TouchableOpacity>
          </>
        )}
      </View>

      {/* Menu */}
      <View style={[styles.menuSection, { backgroundColor: colors.card }]}>
        <MenuItem icon="calendar" label="My Bookings" onPress={() => router.push('/(tabs)/bookings')} />
        <MenuItem icon="heart" label="Saved Salons" onPress={() => router.push('/(tabs)/favorites')} />
        {isOwner && (
          <MenuItem icon="scissors" label="Manage My Salon" onPress={() => router.push('/owner/dashboard')} />
        )}
      </View>

      {isOwner && (
        <View style={[styles.menuSection, { backgroundColor: colors.card, marginTop: 12 }]}>
          <MenuItem icon="bar-chart-2" label="Owner Dashboard" onPress={() => router.push('/owner/dashboard')} />
        </View>
      )}

      <View style={[styles.menuSection, { backgroundColor: colors.card, marginTop: 12 }]}>
        <MenuItem icon="log-out" label="Sign Out" onPress={handleLogout} danger />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  centered: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 16, paddingHorizontal: 32 },
  profileHeader: { alignItems: 'center', paddingHorizontal: 20, paddingBottom: 24, gap: 8 },
  avatar: { width: 88, height: 88, borderRadius: 44, alignItems: 'center', justifyContent: 'center', marginBottom: 8 },
  initials: { fontSize: 32, fontFamily: 'Inter_700Bold' },
  userName: { fontSize: 22, fontFamily: 'Inter_700Bold' },
  userEmail: { fontSize: 15, fontFamily: 'Inter_400Regular' },
  roleBadge: { paddingHorizontal: 14, paddingVertical: 4, borderRadius: 12 },
  roleText: { fontSize: 12, fontFamily: 'Inter_600SemiBold' },
  editProfileBtn: { flexDirection: 'row', alignItems: 'center', gap: 6, paddingHorizontal: 16, paddingVertical: 8, borderWidth: 1, marginTop: 4 },
  editProfileText: { fontSize: 13, fontFamily: 'Inter_500Medium' },
  editFields: { width: '100%', gap: 10 },
  editInput: { height: 48, paddingHorizontal: 14, borderWidth: 1, fontSize: 15 },
  editActions: { flexDirection: 'row', gap: 10 },
  editBtn: { flex: 1, height: 44, alignItems: 'center', justifyContent: 'center' },
  editBtnText: { fontSize: 15, fontFamily: 'Inter_600SemiBold' },
  menuSection: { marginHorizontal: 0, marginTop: 12 },
  menuItem: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 20, paddingVertical: 16, gap: 14, borderBottomWidth: 1 },
  menuIcon: { width: 36, height: 36, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  menuLabel: { flex: 1, fontSize: 16, fontFamily: 'Inter_500Medium' },
  headerTitle: { fontSize: 24, fontFamily: 'Inter_700Bold' },
  emptyText: { fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center', lineHeight: 22 },
  signInBtn: { paddingHorizontal: 40, paddingVertical: 14, marginTop: 8, width: '100%', alignItems: 'center' },
  signInBtnText: { fontSize: 15, fontFamily: 'Inter_600SemiBold' },
  registerLink: { fontSize: 15, fontFamily: 'Inter_500Medium' },
});
