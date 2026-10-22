use rust_decimal::Decimal;

#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum ErroreCalcolo {
    #[error("{campo}: valore {valore} fuori dall'intervallo ammesso (±{limite})")]
    FuoriIntervallo {
        campo: &'static str,
        valore: Decimal,
        limite: Decimal,
    },

    #[error("aliquota IVA sconosciuta: {0}")]
    AliquotaSconosciuta(String),

    #[error("sconto non valido: \"{0}\"")]
    ScontoNonValido(String),

    #[error("dilazione di {giorni} giorni non esprimibile in mesi interi con partenza a fine mese")]
    DilazioneNonMensile { giorni: u16 },

    #[error("condizione di pagamento {codice} senza rate")]
    PagamentoSenzaRate { codice: String },

    #[error(
        "condizione di pagamento {codice}: le rate coprono {imponibile}% dell'imponibile e {imposta}% dell'imposta"
    )]
    RateIncomplete {
        codice: String,
        imponibile: Decimal,
        imposta: Decimal,
    },

    #[error("data di scadenza fuori dal calendario gestito")]
    DataFuoriCalendario,
}
