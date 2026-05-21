import React, { useState, useEffect } from 'react';
import {
  StyleSheet, View, Text, TextInput, TouchableOpacity, ScrollView, Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import { useCreateSalon, useUpdateSalon, useGetSalon, getGetMySalonsQueryKey } from '@workspace/api-client-react';
import { useQueryClient } from '@tanstack/react-query';
import { router, useLocalSearchParams } from 'expo-router';
import { KeyboardAwareScrollViewCompat } from '@/components/KeyboardAwareScrollViewCompat';
import * as Haptics from 'expo-haptics';

export default function SalonFormScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const queryClient = useQueryClient();
  const { salonId } = useLocalSearchParams<{ salonId: string }>();
  const isEdit = !!salonId;

  const createSalon = useCreateSalon();
  const updateSalon = useUpdateSalon();

  const { data: existingSalon } = useGetSalon(parseInt(salonId ?? '0', 10), {
    query: { enabled: isEdit && !!salonId },
  });

  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [address, setAddress] = useState('');
  const [city, setCity] = useState('');
  const [phone, setPhone] = useState('');
  const [openTime, setOpenTime] = useState('09:00');
  const [closeTime, setCloseTime] = useState('20:00');
  const [totalSeats, setTotalSeats] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (existingSalon) {
      setName(existingSalon.name ?? '');
      setDescription(existingSalon.description ?? '');
      setAddress(existingSalon.address ?? '');
      setCity(existingSalon.city ?? '');
      setPhone(existingSalon.phone ?? '');
      setOpenTime(existingSalon.openTime ?? '09:00');
      setCloseTime(existingSalon.closeTime ?? '20:00');
      setTotalSeats(existingSalon.totalSeats != null ? String(existingSalon.totalSeats) : '');
    }
  }, [existingSalon]);

  const handleSubmit = async () => {
    if (!name || !address || !city) {
      setError('Name, address, and city are required');
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    try {
      const payload = {
        name,
        description: description || null,
        address,
        city,
        phone: phone || null,
        openTime,
        closeTime,
        totalSeats: totalSeats ? parseInt(totalSeats, 10) : null,
      };
      if (isEdit && salonId) {
        await updateSalon.mutateAsync({ id: parseInt(salonId, 10), data: payload });
      } else {
        await createSalon.mutateAsync({ data: payload });
      }
      queryClient.invalidateQueries({ queryKey: getGetMySalonsQueryKey() });
      router.back();
    } catch (e: any) {
      setError(e?.message ?? `Failed to ${isEdit ? 'update' : 'create'} salon`);
    }
  };

  const isPending = createSalon.isPending || updateSalon.isPending;

  const fields = [
    { label: 'Salon Name *', value: name, setter: setName, placeholder: 'e.g. Golden Scissors' },
    { label: 'Description', value: description, setter: setDescription, placeholder: 'Tell clients about your salon...' },
    { label: 'Address *', value: address, setter: setAddress, placeholder: '123 Main Street' },
    { label: 'City *', value: city, setter: setCity, placeholder: 'New York' },
    { label: 'Phone', value: phone, setter: setPhone, placeholder: '+1 234 567 8900' },
    { label: 'Opening Time', value: openTime, setter: setOpenTime, placeholder: '09:00' },
    { label: 'Closing Time', value: closeTime, setter: setCloseTime, placeholder: '20:00' },
    { label: 'Total Seats / Chairs', value: totalSeats, setter: setTotalSeats, placeholder: 'e.g. 8', keyboard: 'numeric' as const },
  ];

  return (
    <KeyboardAwareScrollViewCompat>
      <View style={[styles.container, { backgroundColor: colors.background }]}>
        <View style={[styles.header, { paddingTop: topInset, backgroundColor: colors.background, borderBottomColor: colors.border }]}>
          <TouchableOpacity onPress={() => router.back()}>
            <Feather name="x" size={22} color={colors.foreground} />
          </TouchableOpacity>
          <Text style={[styles.headerTitle, { color: colors.foreground }]}>{isEdit ? 'Edit Salon' : 'New Salon'}</Text>
          <View style={{ width: 22 }} />
        </View>

        <View style={styles.form}>
          {error ? <Text style={styles.errorText}>{error}</Text> : null}

          {fields.map(({ label, value, setter, placeholder, keyboard }) => (
            <View key={label} style={styles.field}>
              <Text style={[styles.fieldLabel, { color: colors.mutedForeground }]}>{label}</Text>
              <TextInput
                style={[styles.input, { backgroundColor: colors.input, borderColor: colors.border, color: colors.foreground, borderRadius: 8 }]}
                value={value}
                onChangeText={setter}
                placeholder={placeholder}
                placeholderTextColor={colors.mutedForeground}
                multiline={label === 'Description'}
                numberOfLines={label === 'Description' ? 3 : 1}
                keyboardType={keyboard ?? 'default'}
              />
            </View>
          ))}

          <TouchableOpacity
            style={[styles.submitBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
            onPress={handleSubmit}
            disabled={isPending}
          >
            <Text style={[styles.submitBtnText, { color: colors.primaryForeground }]}>
              {isPending ? (isEdit ? 'Saving...' : 'Creating...') : (isEdit ? 'Save Changes' : 'Create Salon')}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </KeyboardAwareScrollViewCompat>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingBottom: 14, borderBottomWidth: 1 },
  headerTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  form: { padding: 16 },
  field: { marginBottom: 20 },
  fieldLabel: { fontSize: 13, fontFamily: 'Inter_500Medium', marginBottom: 6, textTransform: 'uppercase', letterSpacing: 0.5 },
  input: { paddingHorizontal: 14, paddingVertical: 12, borderWidth: 1, fontSize: 15, fontFamily: 'Inter_400Regular' },
  errorText: { color: '#ef4444', fontSize: 14, fontFamily: 'Inter_400Regular', marginBottom: 16 },
  submitBtn: { height: 52, alignItems: 'center', justifyContent: 'center', marginTop: 8 },
  submitBtnText: { fontSize: 16, fontFamily: 'Inter_600SemiBold' },
});
