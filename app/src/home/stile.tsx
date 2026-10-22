// I segni del marchio usati nei widget della Home: strisce diagonali ed etichette fra virgolette.

import { useId } from "react";

/** Strisce diagonali del marchio, in piccolo: la firma dei widget. */
export function Strisce({ className = "size-3" }: { className?: string }) {
  const ritaglio = useId();
  return (
    <svg viewBox="0 0 12 12" className={className} aria-hidden>
      <clipPath id={ritaglio}>
        <rect width="12" height="12" />
      </clipPath>
      <path
        clipPath={`url(#${ritaglio})`}
        fill="currentColor"
        d="M-12,12 l12,-12 h2 l-12,12 Z M-8,12 l12,-12 h2 l-12,12 Z M-4,12 l12,-12 h2 l-12,12 Z M0,12 l12,-12 h2 l-12,12 Z M4,12 l12,-12 h2 l-12,12 Z M8,12 l12,-12 h2 l-12,12 Z"
      />
    </svg>
  );
}

/** Etichetta alla Off-White, come nel marchio: maiuscole spaziate fra virgolette. */
export function Etichetta({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return <span className={`text-[11px] font-semibold uppercase tracking-[0.2em] ${className}`}>"{children}"</span>;
}
