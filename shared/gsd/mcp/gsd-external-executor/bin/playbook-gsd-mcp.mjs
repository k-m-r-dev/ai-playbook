#!/usr/bin/env node
import { pathToFileURL } from "node:url";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
await import(pathToFileURL(join(here, "../src/server.mjs")).href);
