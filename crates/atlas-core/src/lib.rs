//! Motore di calcolo di ATLAS.
//!
//! Regole di dominio pure, senza I/O e senza stato globale. Ogni regola riproduce il
//! comportamento registrato da Arca Evolution sullo storico aziendale ed è verificata
//! dal programma `atlas-verify` documento per documento.
//!
//! Le grandezze in ingresso sono limitate in costruzione ([`importo::Limitato`]): oltre
//! quel confine nessuna operazione aritmetica del motore può andare in overflow.

pub mod aliquota;
pub mod ddt;
pub mod differita;
pub mod errore;
pub mod importo;
pub mod iva;
pub mod numerazione;
pub mod pagamento;
pub mod riga;

pub use errore::ErroreCalcolo;
