import React, { useState } from 'react';
import {
  StyleSheet, View, Text, TouchableOpacity, ScrollView, Platform, TextInput, Alert, Modal,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import {
  useGetSalonServices, useCreateService, useUpdateService, useDeleteService,
  getGetSalonServicesQueryKey,
} from '@workspace/api-client-react';
import { useQueryClient } from '@tanstack/react-query';
import { router, useLocalSearchParams } from 'expo-router';
import * as Haptics from 'expo-haptics';

type ServiceForm = {
  name: string;
  description: string;
  price: string;
  durationMinutes: string;
  category: string;
};

const EMPTY_FORM: ServiceForm = { name: '', description: '', price: '', durationMinutes: '60', category: '' };

export default function ServicesScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { salonId } = useLocalSearchParams<{ salonId: string }>();
  const salonIdNum = parseInt(salonId ?? '0', 10);
  const queryClient = useQueryClient();
  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;

  const { data: services, isLoading } = useGetSalonServices(salonIdNum, { query: { enabled: !!salonIdNum } });
  const createService = useCreateService();
  const updateService = useUpdateService();
  const deleteService = useDeleteService();

  const [modal, setModal] = useState<null | 'create' | 'edit'>(null);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [form, setForm] = useState<ServiceForm>(EMPTY_FORM);
  const [error, setError] = useState('');

  const invalidate = () => queryClient.invalidateQueries({ queryKey: getGetSalonServicesQueryKey(salonIdNum) });

  const openCreate = () => {
    setForm(EMPTY_FORM);
    setEditingId(null);
    setError('');
    setModal('create');
  };

  const openEdit = (s: any) => {
    setForm({
      name: s.name ?? '',
      description: s.description ?? '',
      price: String(s.price ?? ''),
      durationMinutes: String(s.durationMinutes ?? 60),
      category: s.category ?? '',
    });
    setEditingId(s.id);
    setError('');
    setModal('edit');
  };

  const handleSave = async () => {
    if (!form.name || !form.price) { setError('Name and price are required'); return; }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    try {
      const payload = {
        name: form.name,
        description: form.description || null,
        price: parseFloat(form.price),
        durationMinutes: parseInt(form.durationMinutes, 10) || 60,
        category: form.category || null,
      };
      if (modal === 'create') {
        await createService.mutateAsync({ salonId: salonIdNum, data: payload });
      } else if (modal === 'edit' && editingId) {
        await updateService.mutateAsync({ salonId: salonIdNum, serviceId: editingId, data: payload });
      }
      invalidate();
      setModal(null);
    } catch (e: any) {
      setError(e?.message ?? 'Failed to save');
    }
  };

  const handleDelete = (id: number) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    if (Platform.OS === 'web') {
      if (window.confirm('Delete this service?')) {
        deleteService.mutateAsync({ salonId: salonIdNum, serviceId: id }).then(invalidate);
      }
    } else {
      Alert.alert('Delete Service', 'Are you sure?', [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Delete', style: 'destructive', onPress: () => deleteService.mutateAsync({ salonId: salonIdNum, serviceId: id }).then(invalidate) },
      ]);
    }
  };

  const fields: { key: keyof ServiceForm; label: string; placeholder: string; keyboard?: any }[] = [
    { key: 'name', label: 'Service Name *', placeholder: 'e.g. Haircut & Blowdry' },
    { key: 'description', label: 'Description', placeholder: 'Brief description...' },
    { key: 'price', label: 'Price ($) *', placeholder: '45.00', keyboard: 'decimal-pad' },
    { key: 'durationMinutes', label: 'Duration (minutes)', placeholder: '60', keyboard: 'numeric' },
    { key: 'category', label: 'Category', placeholder: 'e.g. Hair, Nails, Skin' },
  ];

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { paddingTop: topInset, backgroundColor: colors.background, borderBottomColor: colors.border }]}>
        <TouchableOpacity onPress={() => router.back()}>
          <Feather name="arrow-left" size={22} color={colors.foreground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Services</Text>
        <TouchableOpacity onPress={openCreate}>
          <Feather name="plus" size={22} color={colors.primary} />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 32 }}>
        {isLoading ? (
          <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>Loading...</Text>
        ) : !services?.length ? (
          <View style={styles.empty}>
            <Feather name="scissors" size={48} color={colors.mutedForeground} />
            <Text style={[styles.emptyTitle, { color: colors.foreground }]}>No services yet</Text>
            <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>Add services that clients can book</Text>
            <TouchableOpacity
              style={[styles.addBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
              onPress={openCreate}
            >
              <Text style={[styles.addBtnText, { color: colors.primaryForeground }]}>Add First Service</Text>
            </TouchableOpacity>
          </View>
        ) : (
          services.map((s) => (
            <View key={s.id} style={[styles.card, { backgroundColor: colors.card, borderRadius: colors.radius }]}>
              <View style={styles.cardBody}>
                <View style={styles.cardInfo}>
                  <Text style={[styles.serviceName, { color: colors.foreground }]}>{s.name}</Text>
                  {s.category && <Text style={[styles.serviceCategory, { color: colors.primary }]}>{s.category}</Text>}
                  <View style={styles.serviceMeta}>
                    <Text style={[styles.servicePrice, { color: colors.foreground }]}>${s.price.toFixed(2)}</Text>
                    <Text style={[styles.serviceDuration, { color: colors.mutedForeground }]}> · {s.durationMinutes} min</Text>
                  </View>
                  {s.description ? <Text style={[styles.serviceDesc, { color: colors.mutedForeground }]} numberOfLines={2}>{s.description}</Text> : null}
                </View>
                <View style={styles.cardActions}>
                  <TouchableOpacity
                    style={[styles.actionBtn, { backgroundColor: colors.primary + '15', borderRadius: 8 }]}
                    onPress={() => openEdit(s)}
                  >
                    <Feather name="edit-2" size={16} color={colors.primary} />
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[styles.actionBtn, { backgroundColor: '#ef444420', borderRadius: 8 }]}
                    onPress={() => handleDelete(s.id)}
                  >
                    <Feather name="trash-2" size={16} color="#ef4444" />
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          ))
        )}
      </ScrollView>

      <Modal visible={modal !== null} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={[styles.modalSheet, { backgroundColor: colors.background, borderTopLeftRadius: 20, borderTopRightRadius: 20 }]}>
            <View style={[styles.modalHeader, { borderBottomColor: colors.border }]}>
              <Text style={[styles.modalTitle, { color: colors.foreground }]}>{modal === 'create' ? 'New Service' : 'Edit Service'}</Text>
              <TouchableOpacity onPress={() => setModal(null)}>
                <Feather name="x" size={22} color={colors.foreground} />
              </TouchableOpacity>
            </View>
            <ScrollView style={styles.modalContent}>
              {error ? <Text style={styles.errorText}>{error}</Text> : null}
              {fields.map(({ key, label, placeholder, keyboard }) => (
                <View key={key} style={styles.field}>
                  <Text style={[styles.fieldLabel, { color: colors.mutedForeground }]}>{label}</Text>
                  <TextInput
                    style={[styles.input, { backgroundColor: colors.input, borderColor: colors.border, color: colors.foreground, borderRadius: 8 }]}
                    value={form[key]}
                    onChangeText={(v) => setForm((f) => ({ ...f, [key]: v }))}
                    placeholder={placeholder}
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType={keyboard ?? 'default'}
                  />
                </View>
              ))}
              <TouchableOpacity
                style={[styles.saveBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
                onPress={handleSave}
                disabled={createService.isPending || updateService.isPending}
              >
                <Text style={[styles.saveBtnText, { color: colors.primaryForeground }]}>
                  {(createService.isPending || updateService.isPending) ? 'Saving...' : 'Save Service'}
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
  empty: { alignItems: 'center', paddingVertical: 60, gap: 12 },
  emptyTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  emptyText: { fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center' },
  addBtn: { paddingHorizontal: 24, paddingVertical: 12, marginTop: 8 },
  addBtnText: { fontSize: 15, fontFamily: 'Inter_600SemiBold' },
  card: { marginBottom: 10, padding: 14 },
  cardBody: { flexDirection: 'row', alignItems: 'flex-start' },
  cardInfo: { flex: 1 },
  serviceName: { fontSize: 16, fontFamily: 'Inter_600SemiBold' },
  serviceCategory: { fontSize: 12, fontFamily: 'Inter_500Medium', marginTop: 2 },
  serviceMeta: { flexDirection: 'row', alignItems: 'center', marginTop: 6 },
  servicePrice: { fontSize: 15, fontFamily: 'Inter_700Bold' },
  serviceDuration: { fontSize: 14, fontFamily: 'Inter_400Regular' },
  serviceDesc: { fontSize: 13, fontFamily: 'Inter_400Regular', marginTop: 4, lineHeight: 18 },
  cardActions: { flexDirection: 'row', gap: 8, marginLeft: 12 },
  actionBtn: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center' },
  modalOverlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: 'rgba(0,0,0,0.5)' },
  modalSheet: { maxHeight: '90%' },
  modalHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', padding: 16, borderBottomWidth: 1 },
  modalTitle: { fontSize: 18, fontFamily: 'Inter_700Bold' },
  modalContent: { padding: 16 },
  field: { marginBottom: 16 },
  fieldLabel: { fontSize: 13, fontFamily: 'Inter_500Medium', marginBottom: 6, textTransform: 'uppercase', letterSpacing: 0.5 },
  input: { paddingHorizontal: 14, paddingVertical: 12, borderWidth: 1, fontSize: 15, fontFamily: 'Inter_400Regular' },
  errorText: { color: '#ef4444', fontSize: 14, fontFamily: 'Inter_400Regular', marginBottom: 16 },
  saveBtn: { height: 52, alignItems: 'center', justifyContent: 'center', marginTop: 8, marginBottom: 32 },
  saveBtnText: { fontSize: 16, fontFamily: 'Inter_600SemiBold' },
});
