import { dataIso } from "./Testata";

test("data battuta come in Arca (GG-MM-AAAA) → ISO", () => {
  expect(dataIso("21-10-2026")).toBe("2026-10-21");
  expect(dataIso("1/2/26")).toBe("2026-02-01");
  expect(dataIso("21.10.2026")).toBe("2026-10-21");
  expect(dataIso("21102026")).toBe("2026-10-21");
  expect(dataIso("31-02-2026")).toBeNull();
  expect(dataIso("2026-10-21")).toBeNull();
  expect(dataIso("")).toBeNull();
});
