import React, { useState } from 'react';
import {
  StyleSheet, View, Text, TouchableOpacity, ScrollView, Platform, TextInput, Alert, Modal,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import {
  useGetSalonStaff, useCreateStaff, getGetSalonStaffQueryKey,
} from '@workspace/api-client-react';
import { useQueryClient } from '@tanstack/react-query';
import { router, useLocalSearchParams } from 'expo-router';
import * as Haptics from 'expo-haptics';

type StaffForm = { name: string; role: string; specialization: string };
const EMPTY_FORM: StaffForm = { name: '', role: '', specialization: '' };

export default function StaffScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { salonId } = useLocalSearchParams<{ salonId: string }>();
  const salonIdNum = parseInt(salonId ?? '0', 10);
  const queryClient = useQueryClient();
  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;

  const { data: staff, isLoading } = useGetSalonStaff(salonIdNum, { query: { enabled: !!salonIdNum } });
  const createStaff = useCreateStaff();

  const [modal, setModal] = useState(false);
  const [form, setForm] = useState<StaffForm>(EMPTY_FORM);
  const [error, setError] = useState('');

  const invalidate = () => queryClient.invalidateQueries({ queryKey: getGetSalonStaffQueryKey(salonIdNum) });

  const handleAdd = async () => {
    if (!form.name) { setError('Name is required'); return; }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    try {
      await createStaff.mutateAsync({
        salonId: salonIdNum,
        data: { name: form.name, role: form.role || null, specialization: form.specialization || null },
      });
      invalidate();
      setModal(false);
      setForm(EMPTY_FORM);
    } catch (e: any) {
      setError(e?.message ?? 'Failed to add staff');
    }
  };

  const initials = (name: string) => name.split(' ').map((n) => n[0]).join('').toUpperCase().slice(0, 2);

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { paddingTop: topInset, backgroundColor: colors.background, borderBottomColor: colors.border }]}>
        <TouchableOpacity onPress={() => router.back()}>
          <Feather name="arrow-left" size={22} color={colors.foreground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Staff Members</Text>
        <TouchableOpacity onPress={() => { setForm(EMPTY_FORM); setError(''); setModal(true); }}>
          <Feather name="plus" size={22} color={colors.primary} />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 32 }}>
        {isLoading ? (
          <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>Loading...</Text>
        ) : !staff?.length ? (
          <View style={styles.empty}>
            <Feather name="users" size={48} color={colors.mutedForeground} />
            <Text style={[styles.emptyTitle, { color: colors.foreground }]}>No staff yet</Text>
            <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>Add your team members so clients can pick their preferred stylist</Text>
            <TouchableOpacity
              style={[styles.addBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
              onPress={() => setModal(true)}
            >
              <Text style={[styles.addBtnText, { color: colors.primaryForeground }]}>Add Staff Member</Text>
            </TouchableOpacity>
          </View>
        ) : (
          staff.map((s) => (
            <View key={s.id} style={[styles.card, { backgroundColor: colors.card, borderRadius: colors.radius }]}>
              <View style={[styles.avatar, { backgroundColor: colors.primary + '20' }]}>
                <Text style={[styles.avatarText, { color: colors.primary }]}>{initials(s.name)}</Text>
              </View>
              <View style={styles.info}>
                <Text style={[styles.staffName, { color: colors.foreground }]}>{s.name}</Text>
                {s.role && <Text style={[styles.staffRole, { color: colors.mutedForeground }]}>{s.role}</Text>}
                {s.specialization && (
                  <View style={[styles.specBadge, { backgroundColor: colors.primary + '15' }]}>
                    <Text style={[styles.specText, { color: colors.primary }]}>{s.specialization}</Text>
                  </View>
                )}
              </View>
              <View style={[styles.statusDot, { backgroundColor: s.isAvailable ? '#22c55e' : colors.mutedForeground }]} />
            </View>
          ))
        )}
      </ScrollView>

      <Modal visible={modal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={[styles.modalSheet, { backgroundColor: colors.background, borderTopLeftRadius: 20, borderTopRightRadius: 20 }]}>
            <View style={[styles.modalHeader, { borderBottomColor: colors.border }]}>
              <Text style={[styles.modalTitle, { color: colors.foreground }]}>Add Staff Member</Text>
              <TouchableOpacity onPress={() => setModal(false)}>
                <Feather name="x" size={22} color={colors.foreground} />
              </TouchableOpacity>
            </View>
            <ScrollView style={{ padding: 16 }}>
              {error ? <Text style={styles.errorText}>{error}</Text> : null}
              {([
                { key: 'name', label: 'Full Name *', placeholder: 'e.g. Sarah Johnson' },
                { key: 'role', label: 'Role', placeholder: 'e.g. Senior Stylist, Colorist' },
                { key: 'specialization', label: 'Specialization', placeholder: 'e.g. Color, Balayage, Cuts' },
              ] as { key: keyof StaffForm; label: string; placeholder: string }[]).map(({ key, label, placeholder }) => (
                <View key={key} style={styles.field}>
                  <Text style={[styles.fieldLabel, { color: colors.mutedForeground }]}>{label}</Text>
                  <TextInput
                    style={[styles.input, { backgroundColor: colors.input, borderColor: colors.border, color: colors.foreground, borderRadius: 8 }]}
                    value={form[key]}
                    onChangeText={(v) => setForm((f) => ({ ...f, [key]: v }))}
                    placeholder={placeholder}
                    placeholderTextColor={colors.mutedForeground}
                  />
                </View>
              ))}
              <TouchableOpacity
                style={[styles.saveBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
                onPress={handleAdd}
                disabled={createStaff.isPending}
              >
                <Text style={[styles.saveBtnText, { color: colors.primaryForeground }]}>
                  {createStaff.isPending ? 'Adding...' : 'Add Staff Member'}
                </Text>
              </TouchableOpacity>
            </ScrollView>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingBottom: 14, borderBottomWidth: 1 },
  headerTitle: { fontSize: 18, fontFamily: 'Inter_700Bold' },
  empty: { alignItems: 'center', paddingVertical: 60, gap: 12, paddingHorizontal: 24 },
  emptyTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  emptyText: { fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center' },
  addBtn: { paddingHorizontal: 24, paddingVertical: 12, marginTop: 8 },
  addBtnText: { fontSize: 15, fontFamily: 'Inter_600SemiBold' },
  card: { flexDirection: 'row', alignItems: 'center', padding: 14, marginBottom: 10, gap: 12 },
  avatar: { width: 48, height: 48, borderRadius: 24, alignItems: 'center', justifyContent: 'center' },
  avatarText: { fontSize: 16, fontFamily: 'Inter_700Bold' },
  info: { flex: 1, gap: 3 },
  staffName: { fontSize: 16, fontFamily: 'Inter_600SemiBold' },
  staffRole: { fontSize: 13, fontFamily: 'Inter_400Regular' },
  specBadge: { alignSelf: 'flex-start', paddingHorizontal: 8, paddingVertical: 2, borderRadius: 6, marginTop: 2 },
  specText: { fontSize: 11, fontFamily: 'Inter_500Medium' },
  statusDot: { width: 10, height: 10, borderRadius: 5 },
  modalOverlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: 'rgba(0,0,0,0.5)' },
  modalSheet: { maxHeight: '80%' },
  modalHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', padding: 16, borderBottomWidth: 1 },
  modalTitle: { fontSize: 18, fontFamily: 'Inter_700Bold' },
  field: { marginBottom: 16 },
  fieldLabel: { fontSize: 13, fontFamily: 'Inter_500Medium', marginBottom: 6, textTransform: 'uppercase', letterSpacing: 0.5 },
  input: { paddingHorizontal: 14, paddingVertical: 12, borderWidth: 1, fontSize: 15, fontFamily: 'Inter_400Regular' },
  errorText: { color: '#ef4444', fontSize: 14, fontFamily: 'Inter_400Regular', marginBottom: 16 },
  saveBtn: { height: 52, alignItems: 'center', justifyContent: 'center', marginTop: 8, marginBottom: 32 },
  saveBtnText: { fontSize: 16, fontFamily: 'Inter_600SemiBold' },
});
