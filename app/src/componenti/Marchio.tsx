// Il marchio ATLAS, disegnato apposta e tutto vettoriale (nessun font da scaricare: l'app lavora
// anche senza rete). Lusso moderno pulito e un tocco alla Off-White:
// - "ATLAS": lettere bastoni ad alto contrasto, Λ senza traversa con l'asta destra piena e la
//   sinistra a filo, aste verticali piene, traverse e piedi a filo, la S con la spina piena e i
//   terminali sottili (spessore secondo la direzione del tratto, come un pennino largo);
// - le strisce diagonali, le virgolette dritte e la firma "c/o BOTTAMEDI".
// Il colore è quello del testo intorno (`currentColor`).

const LETTERE = "M0.0,88.0 L32.0,12.0 L64.0,88.0 L51.5,88.0 L27.8,31.8 L4.2,88.0 Z M98,12 h64 v3.6 h-64 Z M124,12 h12.5 v76 h-12.5 Z M196,12 h12.5 v76 h-12.5 Z M196,84.4 h48 v3.6 h-48 Z M278.0,88.0 L310.0,12.0 L342.0,88.0 L329.5,88.0 L305.8,31.8 L282.2,88.0 Z M428.3,20.7 L427.7,19.8 L427.0,18.8 L426.2,17.9 L425.4,17.1 L424.5,16.4 L423.6,15.7 L422.6,15.1 L421.6,14.5 L420.6,14.1 L419.5,13.7 L418.4,13.4 L417.3,13.2 L416.2,12.9 L415.1,12.8 L414.0,12.6 L412.8,12.5 L411.7,12.3 L410.6,12.2 L409.4,12.2 L408.3,12.1 L407.1,12.1 L405.9,12.0 L404.7,12.0 L403.5,12.0 L401.9,12.0 L400.3,12.0 L398.8,12.1 L397.3,12.3 L395.8,12.4 L394.3,12.7 L392.9,12.9 L391.5,13.3 L390.1,13.7 L388.8,14.2 L387.4,14.7 L386.1,15.3 L384.9,16.1 L383.7,16.9 L382.5,17.9 L381.4,18.9 L380.4,20.1 L379.6,21.4 L378.8,22.7 L378.2,24.2 L377.7,25.7 L377.3,27.2 L377.1,28.9 L377.1,30.5 L377.1,32.3 L377.4,34.1 L377.9,35.8 L378.5,37.3 L379.3,38.8 L380.3,40.1 L381.3,41.3 L382.4,42.4 L383.6,43.4 L384.8,44.2 L386.1,45.0 L387.3,45.6 L388.6,46.3 L389.9,46.9 L391.2,47.5 L392.5,48.0 L393.8,48.5 L395.2,49.0 L396.5,49.5 L397.9,50.0 L399.3,50.5 L400.8,51.0 L402.2,51.5 L403.6,52.0 L405.1,52.6 L406.5,53.2 L407.9,53.9 L409.2,54.5 L410.4,55.2 L411.5,55.9 L412.5,56.6 L413.5,57.4 L414.4,58.2 L415.2,58.9 L415.9,59.8 L416.4,60.6 L416.9,61.4 L417.3,62.2 L417.6,63.0 L417.9,63.8 L418.0,64.5 L418.2,65.2 L418.2,65.9 L418.3,66.7 L418.4,67.4 L418.4,68.1 L418.4,68.9 L418.5,69.8 L418.4,70.6 L418.4,71.4 L418.4,72.1 L418.3,72.8 L418.3,73.5 L418.2,74.2 L418.1,74.9 L417.9,75.7 L417.7,76.4 L417.4,77.2 L417.0,78.0 L416.5,78.8 L415.9,79.6 L415.2,80.3 L414.4,81.0 L413.5,81.7 L412.5,82.3 L411.4,82.8 L410.3,83.3 L409.0,83.6 L407.7,84.0 L406.4,84.2 L405.0,84.3 L403.5,84.4 L402.1,84.4 L400.8,84.3 L399.5,84.1 L398.2,84.0 L397.0,83.7 L395.8,83.5 L394.7,83.1 L393.6,82.8 L392.6,82.4 L391.6,81.9 L390.6,81.4 L389.8,80.9 L388.9,80.3 L388.2,79.7 L387.4,79.2 L386.6,78.7 L385.8,78.2 L385.1,77.7 L384.3,77.2 L383.6,76.7 L382.8,76.2 L382.1,75.7 L381.3,75.1 L380.5,74.5 L377.5,76.5 L377.9,77.6 L378.3,78.7 L378.9,79.7 L379.6,80.7 L380.3,81.6 L381.1,82.5 L382.0,83.3 L383.0,84.0 L384.0,84.7 L385.1,85.3 L386.3,85.7 L387.5,86.1 L388.7,86.4 L389.9,86.7 L391.2,87.0 L392.5,87.2 L393.8,87.4 L395.1,87.6 L396.4,87.7 L397.8,87.8 L399.2,87.9 L400.6,88.0 L402.0,88.0 L403.5,88.0 L405.1,88.0 L406.7,88.0 L408.3,87.9 L409.8,87.7 L411.3,87.6 L412.7,87.3 L414.2,87.1 L415.6,86.8 L417.0,86.4 L418.4,85.9 L419.7,85.4 L421.1,84.8 L422.4,84.2 L423.6,83.4 L424.9,82.5 L426.0,81.5 L427.1,80.4 L428.1,79.1 L428.9,77.8 L429.7,76.3 L430.2,74.8 L430.6,73.2 L430.9,71.5 L430.9,69.8 L430.9,68.1 L430.7,66.5 L430.3,64.9 L429.8,63.4 L429.2,62.0 L428.4,60.6 L427.6,59.3 L426.6,58.2 L425.6,57.1 L424.5,56.1 L423.3,55.2 L422.1,54.4 L420.9,53.6 L419.7,52.9 L418.4,52.3 L417.1,51.6 L415.7,51.0 L414.4,50.4 L413.0,49.8 L411.5,49.3 L410.0,48.7 L408.5,48.2 L407.0,47.7 L405.4,47.2 L404.0,46.6 L402.6,46.1 L401.2,45.6 L399.9,45.0 L398.7,44.4 L397.5,43.8 L396.4,43.2 L395.3,42.5 L394.3,41.9 L393.4,41.1 L392.6,40.4 L391.8,39.6 L391.2,38.8 L390.7,38.0 L390.3,37.2 L390.0,36.4 L389.9,35.7 L389.7,35.0 L389.7,34.2 L389.6,33.6 L389.6,32.9 L389.6,32.1 L389.6,31.4 L389.5,30.5 L389.6,29.7 L389.6,28.9 L389.6,28.1 L389.7,27.4 L389.8,26.7 L389.8,26.0 L389.9,25.3 L390.1,24.5 L390.3,23.8 L390.5,23.0 L390.9,22.2 L391.3,21.5 L391.8,20.7 L392.4,19.9 L393.1,19.2 L393.9,18.5 L394.8,17.9 L395.8,17.3 L396.9,16.8 L398.1,16.4 L399.3,16.1 L400.7,15.8 L402.0,15.7 L403.5,15.6 L404.6,15.6 L405.8,15.7 L406.9,15.7 L408.0,15.8 L409.1,16.0 L410.1,16.1 L411.1,16.3 L412.1,16.5 L413.1,16.8 L414.0,17.1 L414.9,17.5 L415.8,17.8 L416.7,18.3 L417.5,18.7 L418.3,19.1 L419.1,19.5 L419.9,19.9 L420.7,20.4 L421.5,20.8 L422.3,21.2 L423.1,21.7 L423.9,22.2 L424.8,22.7 L425.7,23.3 Z";
const VIRGOLETTE = "M-30,12 h4.6 l-0.9,20 h-2.8 Z M-22,12 h4.6 l-0.9,20 h-2.8 Z M443,12 h4.6 l-0.9,20 h-2.8 Z M451,12 h4.6 l-0.9,20 h-2.8 Z";
const STRISCE_ESTESO = "M-198,88 l76,-76 h12 l-76,76 Z M-174,88 l76,-76 h12 l-76,76 Z M-150,88 l76,-76 h12 l-76,76 Z M-126,88 l76,-76 h12 l-76,76 Z M-102,88 l76,-76 h12 l-76,76 Z M-78,88 l76,-76 h12 l-76,76 Z M-54,88 l76,-76 h12 l-76,76 Z";
const STRISCE_COMPATTO = "M-180,88 l76,-76 h12 l-76,76 Z M-156,88 l76,-76 h12 l-76,76 Z M-132,88 l76,-76 h12 l-76,76 Z M-108,88 l76,-76 h12 l-76,76 Z M-84,88 l76,-76 h12 l-76,76 Z M-60,88 l76,-76 h12 l-76,76 Z M-36,88 l76,-76 h12 l-76,76 Z";
const TESTO = {
  fontFamily: "-apple-system, BlinkMacSystemFont, 'Helvetica Neue', Helvetica, Arial, sans-serif",
  fontWeight: 600,
};

/** In barra: strisce e ATLAS, con la firma accanto in testo vero (leggibile anche piccola). */
export function Marchio({ className = "h-4" }: { className?: string }) {
  return (
    <span className="inline-flex shrink-0 items-center gap-2" role="img" aria-label="ATLAS c/o Bottamedi">
      <svg viewBox="-106 0 543 100" className={`w-auto ${className}`} aria-hidden>
        <defs>
          <clipPath id="marchio-strisce-compatto">
            <rect x="-104" y="12" width="76" height="76" />
          </clipPath>
        </defs>
        <path fill="currentColor" d={STRISCE_COMPATTO} clipPath="url(#marchio-strisce-compatto)" />
        <path fill="currentColor" d={LETTERE} />
      </svg>
      <span className="text-[9.5px] font-semibold uppercase tracking-[0.22em] opacity-55" style={TESTO} aria-hidden>
        c/o Bottamedi
      </span>
    </span>
  );
}

/** Il marchio intero: strisce, "ATLAS" fra virgolette, filo, firma e luogo. */
export function MarchioEsteso({ className = "h-16" }: { className?: string }) {
  return (
    <svg viewBox="-130 -6 623 150" className={`w-auto ${className}`} role="img" aria-label="ATLAS c/o Bottamedi, Mezzolombardo">
      <defs>
        <clipPath id="marchio-strisce-esteso">
          <rect x="-122" y="12" width="76" height="76" />
        </clipPath>
      </defs>
      <path fill="currentColor" d={STRISCE_ESTESO} clipPath="url(#marchio-strisce-esteso)" />
      <path fill="currentColor" d={`${VIRGOLETTE} ${LETTERE}`} />
      <rect x="-122" y="108" width="583" height="0.8" fill="currentColor" opacity="0.5" />
      <text x="-122" y="132" fontSize="15" letterSpacing="4.5" fill="currentColor" style={TESTO}>
        c/o BOTTAMEDI
      </text>
      <text x="461" y="132" fontSize="15" letterSpacing="4.5" textAnchor="end" fill="currentColor" opacity="0.6" style={TESTO}>
        MEZZOLOMBARDO — TN
      </text>
    </svg>
  );
}
