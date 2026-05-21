import { useState } from "react";
import { useGetAdminSalons, useAdminUpdateSalon, getGetAdminSalonsQueryKey } from "@workspace/api-client-react";
import { useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/hooks/use-toast";

export default function SalonsPage() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const { toast } = useToast();
  
  const [page] = useState(1);
  const { data, isLoading } = useGetAdminSalons(
    { page, limit: 50 },
    { query: { enabled: !!token } }
  );

  const updateSalon = useAdminUpdateSalon();

  const handleToggleVerify = async (id: number, currentStatus: boolean) => {
    try {
      await updateSalon.mutateAsync({ id, data: { isVerified: !currentStatus } });
      queryClient.invalidateQueries({ queryKey: getGetAdminSalonsQueryKey() });
      toast({ title: "Salon verification updated" });
    } catch (err) {
      toast({ variant: "destructive", title: "Update failed" });
    }
  };

  const handleToggleActive = async (id: number, currentStatus: boolean) => {
    try {
      await updateSalon.mutateAsync({ id, data: { isActive: !currentStatus } });
      queryClient.invalidateQueries({ queryKey: getGetAdminSalonsQueryKey() });
      toast({ title: "Salon status updated" });
    } catch (err) {
      toast({ variant: "destructive", title: "Update failed" });
    }
  };

  return (
    <div className="p-8 space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Salon Management</h1>
          <p className="text-muted-foreground mt-1">Review and approve vendor salons.</p>
        </div>
      </div>

      <div className="border rounded-md bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Salon</TableHead>
              <TableHead>Location</TableHead>
              <TableHead>Rating</TableHead>
              <TableHead>Verified</TableHead>
              <TableHead>Active</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell><Skeleton className="h-5 w-48" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-32" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-16" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-16" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-16" /></TableCell>
                </TableRow>
              ))
            ) : data?.salons.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-8 text-muted-foreground">No salons found</TableCell>
              </TableRow>
            ) : (
              data?.salons.map((salon) => (
                <TableRow key={salon.id}>
                  <TableCell>
                    <div className="font-medium">{salon.name}</div>
                    <div className="text-xs text-muted-foreground">ID: {salon.id}</div>
                  </TableCell>
                  <TableCell>{salon.city}, {salon.state}</TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1">
                      <span className="text-accent">★</span>
                      <span>{salon.avgRating.toFixed(1)}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Switch 
                        checked={salon.isVerified} 
                        onCheckedChange={() => handleToggleVerify(salon.id, salon.isVerified || false)} 
                      />
                      {salon.isVerified ? (
                        <Badge variant="outline" className="text-green-600 border-green-600/20 bg-green-50">Verified</Badge>
                      ) : (
                        <Badge variant="outline" className="text-yellow-600 border-yellow-600/20 bg-yellow-50">Pending</Badge>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    <Switch 
                      checked={salon.isActive} 
                      onCheckedChange={() => handleToggleActive(salon.id, salon.isActive || false)} 
                    />
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
