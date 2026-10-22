// Clienti: l'elenco con le colonne di quello di Arca e la scheda in una pagina sola, con tutti i
// campi di `CF`, i contatti (`CFContatto`), le destinazioni con tutti i campi di `CFDest` e gli
// ultimi DDT del cliente (la pagina Documenti di Arca). "Nuovo cliente" parte dalla partita IVA: i
// dati ufficiali (VIES) riempiono la scheda, con il codice successivo e i predefiniti di Arca; F10
// lo salva in ATLAS e la replica lo scrive in `CF` e `CFContatto`. I clienti esistenti si
// modificano ancora in Arca.

import { useCallback, useEffect, useState } from "react";
import { ErroreApi, api } from "../api/client";
import type { ClienteBreve, ClienteScheda, DatiAzienda, DdtBreve, Tabelle } from "../api/tipi";
import { data as fData, importo } from "../griglia/numeri";
import type { Griglia } from "../griglia/layout";
import { Area, type PaginaAnagrafica } from "./Area";
import { type Record_, SEZIONI_CLIENTE, corpoNuovoCliente, nuovoCliente, recordCliente } from "./campi";
import type { Colonna } from "./GrigliaElenco";
import { PartitaIva } from "./PartitaIva";
import { AltriCampi, Scheda, Tabella } from "./Scheda";

const x = (r: ClienteBreve, colonna: string) => {
  const v = r.extra?.[colonna];
  return v === null || v === undefined ? "" : String(v).trimEnd();
};
/** Dal contatto principale (l'"Aziendale" di `CFContatto`), come le colonne di Arca. */
const k = (r: ClienteBreve, colonna: string) => {
  const v = r.contatto?.[colonna];
  return v === null || v === undefined ? "" : String(v);
};
const TIPI_CONTATTO: Record<string, string> = { "-1": "Aziendale", "1": "Persona", "-5": "Destinazione diversa" };

/** Le colonne dell'elenco clienti di Arca, nel suo ordine. */
export const COLONNE_CLIENTI: Colonna<ClienteBreve>[] = [
  { id: "ragione_sociale", etichetta: "Ragione Sociale", larghezza: 280, valore: (r) => r.ragione_sociale },
  { id: "codice", etichetta: "Codice", larghezza: 70, valore: (r) => r.codice },
  { id: "indirizzo", etichetta: "Indirizzo", larghezza: 200, valore: (r) => r.indirizzo ?? "" },
  { id: "cap", etichetta: "CAP", larghezza: 50, valore: (r) => r.cap ?? "" },
  { id: "localita", etichetta: "Località", larghezza: 150, valore: (r) => r.localita ?? "" },
  { id: "provincia", etichetta: "Provincia", larghezza: 55, valore: (r) => r.provincia ?? "" },
  { id: "nazione", etichetta: "Nazione", larghezza: 50, valore: (r) => r.nazione ?? "" },
  { id: "telefono", etichetta: "Telefono", larghezza: 100, valore: (r) => k(r, "Telefono") },
  { id: "fax", etichetta: "Fax", larghezza: 90, valore: (r) => k(r, "Fax") },
  { id: "codice_destinatario", etichetta: "Cod.Dest./Email B2B", larghezza: 130, valore: (r) => r.codice_destinatario ?? "" },
  { id: "partita_iva", etichetta: "Partita Iva", larghezza: 100, valore: (r) => r.partita_iva ?? "" },
  { id: "codice_fiscale", etichetta: "Cod.Fiscale", larghezza: 130, valore: (r) => r.codice_fiscale ?? "" },
  { id: "famiglia", etichetta: "Famiglia", larghezza: 60, valore: (r) => x(r, "Cd_CFGruppo1") },
  { id: "gruppo", etichetta: "Gruppo", larghezza: 60, valore: (r) => x(r, "Cd_CFGruppo2") },
  { id: "sottogruppo", etichetta: "Sottogruppo", larghezza: 75, valore: (r) => x(r, "Cd_CFGruppo3") },
  { id: "email", etichetta: "Email", larghezza: 180, valore: (r) => k(r, "Email") },
];

export const GRIGLIA_CLIENTI: Griglia = { colonne: COLONNE_CLIENTI, chiave: "atlas.griglia.clienti", fisse: ["ragione_sociale"] };

const OBSOLETO = "text-zinc-400 line-through decoration-zinc-300 dark:text-zinc-600";

export function Clienti({ attivo, onApriDdt }: { attivo: boolean; onApriDdt: (id: number) => void }) {
  const [righe, setRighe] = useState<ClienteBreve[]>([]);
  const [tabelle, setTabelle] = useState<Tabelle | null>(null);
  const [errore, setErrore] = useState<string | null>(null);
  const [giro, setGiro] = useState(0);
  const [pagina, setPagina] = useState<PaginaAnagrafica>("Elenco");
  const [aperto, setAperto] = useState<string | null>(null);
  const [scheda, setScheda] = useState<ClienteScheda | null>(null);
  /** Il cliente nuovo in battitura (non salvato), finché non si apre un altro cliente. */
  const [bozza, setBozza] = useState<Record_ | null>(null);
  const [partitaIva, setPartitaIva] = useState(false);
  const [documenti, setDocumenti] = useState<DdtBreve[]>([]);
  /** Esito dell'ultimo salvataggio: problemi da correggere o cliente salvato. */
  const [esito, setEsito] = useState<{ errore: boolean; testo: string; dettagli: string[] } | null>(null);

  useEffect(() => {
    if (!attivo) return;
    let valida = true;
    Promise.all([api.elencoClienti(), api.tabelle()])
      .then(([c, t]) => {
        if (!valida) return;
        setRighe(c);
        setTabelle(t);
        setErrore(null);
      })
      .catch((e: Error) => valida && setErrore(e.message));
    return () => {
      valida = false;
    };
  }, [attivo, giro]);

  useEffect(() => {
    if (!aperto) {
      setScheda(null);
      setDocumenti([]);
      return;
    }
    let valida = true;
    api.cliente(aperto).then(
      (s) => valida && setScheda(s),
      (e: Error) => valida && setErrore(e.message),
    );
    api.elencoDdt({ cliente: aperto, limite: 30 }).then(
      (d) => valida && setDocumenti(d),
      () => valida && setDocumenti([]),
    );
    return () => {
      valida = false;
    };
  }, [aperto, giro]);

  const apri = useCallback((codice: string) => {
    setBozza(null);
    setEsito(null);
    setAperto(codice);
  }, []);
  const aggiorna = useCallback(() => setGiro((g) => g + 1), []);

  const crea = async (dati: DatiAzienda | null, numero: string) => {
    setPartitaIva(false);
    const codice = await api.prossimoCodiceCliente().catch(() => "");
    setBozza(nuovoCliente(codice, dati, numero));
    setEsito(null);
    setPagina("Scheda");
  };

  const salva = useCallback(async () => {
    if (!bozza) return;
    try {
      const creato = await api.creaCliente(corpoNuovoCliente(bozza));
      setEsito({ errore: false, testo: `Cliente ${creato.codice} salvato: in coda per Arca`, dettagli: [] });
      setBozza(null);
      setAperto(creato.codice);
      setGiro((g) => g + 1);
    } catch (e) {
      setEsito({
        errore: true,
        testo: e instanceof ErroreApi ? e.message : String(e),
        dettagli: e instanceof ErroreApi ? e.dettagli : [],
      });
    }
  }, [bozza]);

  const avvisoEsito = esito && (
    <div
      role={esito.errore ? "alert" : "status"}
      className={`mb-3 rounded-md px-3 py-1.5 text-[12px] ${
        esito.errore ? "bg-rose-500/10 text-rose-700 dark:text-rose-300" : "bg-emerald-500/12 text-emerald-800 dark:text-emerald-300"
      }`}
    >
      {esito.testo}
      {esito.dettagli.length > 0 && (
        <ul className="mt-1 list-disc pl-5">
          {esito.dettagli.map((d) => (
            <li key={d}>{d}</li>
          ))}
        </ul>
      )}
    </div>
  );

  let contenuto: React.ReactNode;
  if (bozza) {
    contenuto = (
      <Scheda
        nome="Scheda cliente"
        titolo={`Nuovo cliente ${bozza.Cd_CF ?? ""}`}
        sottotitolo={String(bozza.Descrizione || "Ragione sociale da battere")}
        sezioni={SEZIONI_CLIENTE}
        record={bozza}
        tabelle={tabelle}
        onCambia={(colonna, valore) => setBozza((b) => (b ? { ...b, [colonna]: valore } : b))}
        avviso={
          <>
            {avvisoEsito}
            <p className="mb-3 text-[11.5px] text-zinc-500">
              Obbligatori: ragione sociale e partita IVA o codice fiscale. Gli altri campi che Arca vuole li completa ATLAS con i suoi
              predefiniti. <kbd className="tasto">F10</kbd> salva: il cliente è subito in ATLAS e la replica lo scrive in Arca.
            </p>
          </>
        }
      />
    );
  } else if (scheda) {
    contenuto = (
      <Scheda
        nome="Scheda cliente"
        titolo={
          <>
            <span className="font-mono text-zinc-500">{scheda.codice}</span> {scheda.ragione_sociale}
          </>
        }
        sottotitolo={[scheda.indirizzo, [scheda.cap, scheda.localita, scheda.provincia && `(${scheda.provincia})`].filter(Boolean).join(" ")].filter(Boolean).join(" — ")}
        sezioni={SEZIONI_CLIENTE}
        record={recordCliente(scheda)}
        tabelle={tabelle}
        avviso={
          <>
            {avvisoEsito}
            {scheda.obsoleto && <p className="mb-2 text-[12px] font-semibold text-rose-600">Cliente obsoleto</p>}
            {(!scheda.extra || Object.keys(scheda.extra).length === 0) && (
              <p role="note" className="mb-3 rounded-md bg-amber-500/12 px-3 py-1.5 text-[12px] text-amber-800 dark:text-amber-300">
                Solo i campi principali: il database ATLAS va riallineato con <code>importa-anagrafiche</code> per avere tutti i campi di Arca.
              </p>
            )}
            <p className="mb-3 text-[11.5px] text-zinc-500">In sola lettura: le anagrafiche si modificano in Arca e l'importazione le riallinea.</p>
          </>
        }
        aggiunte={{
          contatti: (
            <Tabella
              nome="Contatti"
              intestazioni={[{ testo: "Descrizione" }, { testo: "Tipo" }, { testo: "Destinazione" }, { testo: "Altri campi di Arca" }]}
              righe={scheda.contatti.map((c) => [
                String(c.dati.Descrizione ?? ""),
                TIPI_CONTATTO[String(c.dati.Id_CFContattoTipo)] ?? String(c.dati.Id_CFContattoTipo ?? ""),
                c.destinazione ?? "",
                <AltriCampi dati={c.dati} escluse={["Descrizione", "Id_CFContattoTipo", "Id_CFContatto", "Cd_CF", "Cd_CFDest"]} />,
              ])}
              vuota="Nessun contatto in Arca (o database ATLAS da riallineare con importa-anagrafiche)"
            />
          ),
          ddt: (
            <Tabella
              nome="Destinazioni"
              intestazioni={[
                { testo: "Codice" },
                { testo: "Descrizione" },
                { testo: "Indirizzo" },
                { testo: "Località" },
                { testo: "Prov." },
                { testo: "Predefinita" },
                { testo: "Cod.Dest./PEC" },
                { testo: "Cod. IPA" },
                { testo: "Codice export" },
                { testo: "Altri campi di Arca" },
              ]}
              righe={scheda.destinazioni.map((d) => [
                <span className="font-mono">{d.codice}</span>,
                <span className={d.obsoleto ? OBSOLETO : ""}>{d.descrizione}</span>,
                d.indirizzo ?? "",
                d.localita ?? "",
                d.provincia ?? "",
                d.predefinita ? "✓" : "",
                String(d.extra?.CodiceFPR ?? ""),
                String(d.extra?.CodiceIPA ?? ""),
                String(d.extra?.xCd_Exp ?? ""),
                <AltriCampi dati={d.extra} escluse={["CodiceFPR", "CodiceIPA", "xCd_Exp"]} />,
              ])}
              vuota="Nessuna destinazione diversa"
            />
          ),
          documenti: (
            <Tabella
              nome="Documenti del cliente"
              intestazioni={[{ testo: "Numero", numerica: true }, { testo: "Data" }, { testo: "Destinazione" }, { testo: "Righe", numerica: true }, { testo: "Tot. Doc.", numerica: true }, { testo: "" }]}
              righe={documenti.map((d) => [
                d.numero,
                fData(d.data),
                d.descrizione_destinazione ?? d.destinazione ?? "",
                d.righe,
                importo(d.totale_documento),
                <button type="button" className="text-primario-testo hover:underline" onClick={() => onApriDdt(d.id)}>
                  Apri
                </button>,
              ])}
              vuota="Nessun DDT del cliente in ATLAS"
            />
          ),
        }}
      />
    );
  } else {
    contenuto = (
      <div className="flex h-full items-center justify-center text-sm text-zinc-500">
        {aperto ? "Carico…" : "Scegli un cliente nell'elenco (Invio o doppio clic), o Nuovo cliente (Ctrl+N)."}
      </div>
    );
  }

  return (
    <>
      <Area
        attivo={attivo && !partitaIva}
        nome="Clienti"
        griglia={GRIGLIA_CLIENTI}
        colonne={COLONNE_CLIENTI}
        righe={righe}
        chiave={(r) => r.codice}
        classeRiga={(r) => (r.obsoleto ? OBSOLETO : undefined)}
        piede={<span className={`rounded-sm border border-zinc-300 px-1 dark:border-zinc-700 ${OBSOLETO}`}>Obsoleto</span>}
        errore={errore}
        aperto={bozza ? null : aperto}
        onApri={apri}
        pagina={pagina}
        onPagina={setPagina}
        scheda={contenuto}
        nuovo="Nuovo cliente"
        onNuovo={() => setPartitaIva(true)}
        onSalva={bozza ? () => void salva() : undefined}
        onAggiorna={aggiorna}
      />
      {partitaIva && (
        <PartitaIva
          onChiudi={() => setPartitaIva(false)}
          onNuovo={crea}
          onApri={(codice) => {
            setPartitaIva(false);
            apri(codice);
            setPagina("Scheda");
          }}
        />
      )}
    </>
  );
}
