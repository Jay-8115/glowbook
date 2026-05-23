import bcrypt from "bcrypt";

async function main() {
  const hashInUsers = "$2b$10$c1d59MoUTQ5nGLRmMMCBlulFpGoKtYOuKYE2lEtYqSHflnj5kE0bu";
  const hashInAdmins = "$2b$10$u7f8JjJ3h5IDtwqWGfZ5K.yBcPo4nkzrHET4VRjQNyqqzqvjAUmzy";
  
  const matchesUsers = await bcrypt.compare("password123", hashInUsers);
  const matchesAdmins = await bcrypt.compare("password123", hashInAdmins);
  
  console.log("matchesUsers:", matchesUsers);
  console.log("matchesAdmins:", matchesAdmins);
}

main().catch(console.error);
