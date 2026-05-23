import { useState } from "react";
import { useGetAdminUsers, useAdminUpdateUser, useAdminDeleteUser, getGetAdminUsersQueryKey } from "@workspace/api-client-react";
import { useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/hooks/use-toast";

export default function UsersPage() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const { toast } = useToast();
  
  const [page] = useState(1);
  const [role, setRole] = useState<string>("all");
  
  const { data, isLoading } = useGetAdminUsers(
    { page, limit: 50, role: role !== "all" ? role as any : undefined },
    { query: { enabled: !!token } as any }
  );

  const updateUser = useAdminUpdateUser();
  const deleteUser = useAdminDeleteUser();



  return (
    <div className="p-8 space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Users Management</h1>
          <p className="text-muted-foreground mt-1">Manage platform users, owners, and administrators.</p>
        </div>
      </div>

      <div className="flex gap-4 items-center">
        <Input placeholder="Search users..." className="max-w-sm" />
        <Select value={role} onValueChange={setRole}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Filter by role" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Roles</SelectItem>
            <SelectItem value="user">User</SelectItem>
            <SelectItem value="owner">Owner</SelectItem>
            <SelectItem value="admin">Admin</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="border rounded-md bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Joined</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell><Skeleton className="h-5 w-32" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-48" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-16" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-24" /></TableCell>
                  <TableCell><Skeleton className="h-5 w-16 ml-auto" /></TableCell>
                </TableRow>
              ))
            ) : data?.users?.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-8 text-muted-foreground">No users found</TableCell>
              </TableRow>
            ) : (
              data?.users?.map((user) => (
                <TableRow key={user.id}>
                  <TableCell className="font-medium">{user.name}</TableCell>
                  <TableCell>{user.email}</TableCell>
                  <TableCell>
                    <Badge variant={user.role === 'admin' ? 'default' : user.role === 'owner' ? 'secondary' : 'outline'}>
                      {user.role}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {new Date(user.createdAt).toLocaleDateString()}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2 items-center">
                      <Button variant="destructive" size="sm" className="h-8" onClick={async () => {
                        if (confirm("Are you sure you want to delete this user?")) {
                          try {
                            await deleteUser.mutateAsync({ id: user.id });
                            queryClient.invalidateQueries({ queryKey: getGetAdminUsersQueryKey() });
                            toast({ title: "User deleted" });
                          } catch (err) {
                            toast({ variant: "destructive", title: "Failed to delete user" });
                          }
                        }
                      }}>
                        Delete
                      </Button>
                    </div>
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
