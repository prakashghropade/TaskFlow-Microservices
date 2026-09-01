// import { config } from "dotenv";
// import { readFileSync } from "node:fs";
// import { resolve } from "node:path";
// import { getPool, closePool } from "../packages/shared/src/db/pool.ts";

// config({ path: resolve(process.cwd(), ".env") });

// async function main() {
//   const file = process.argv[2] ?? "sql/001_users.sql";
//   const sql = readFileSync(resolve(process.cwd(), file), "utf-8");

//   const pool = getPool();
//   await pool.query(sql);
//   console.log(`Migrated: ${file}`);
//   await closePool();
// }

// main().catch((err) => {
//   console.error(err);
//   process.exit(1);
// });




import { config } from "dotenv";
import { readFileSync, readdirSync } from "node:fs";
import { resolve } from "node:path";
import { getPool, closePool } from "../packages/shared/src/db/pool.ts";

config({ path: resolve(process.cwd(), ".env") });

async function main() {
  const pool = getPool();

  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id SERIAL PRIMARY KEY,
      filename VARCHAR(255) UNIQUE NOT NULL,
      executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);

  const sqlDir = resolve(process.cwd(), "sql");

  const files = readdirSync(sqlDir)
    .filter((file) => file.endsWith(".sql"))
    .sort();

  for (const file of files) {
    const result = await pool.query(
      "SELECT 1 FROM schema_migrations WHERE filename = $1",
      [file]
    );

    if ((result.rowCount ?? 0) > 0) {
      console.log(`Skipping: ${file}`);
      continue;
    }

    const sql = readFileSync(resolve(sqlDir, file), "utf-8");

    console.log(`Running: ${file}`);

    await pool.query("BEGIN");

    try {
      await pool.query(sql);

      await pool.query(
        "INSERT INTO schema_migrations (filename) VALUES ($1)",
        [file]
      );

      await pool.query("COMMIT");

      console.log(`Migrated: ${file}`);
    } catch (error) {
      await pool.query("ROLLBACK");
      throw error;
    }
  }

  await closePool();
}

main().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});