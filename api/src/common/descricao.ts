// RF02 exige saude; DER p.25 oferece apenas descricao (string).
// Codificacao versionada do valor, sem adicionar atributo ao modelo fisico.
export function codificarDescricao(descricao: string, saude: string): string {
  return JSON.stringify({
    miar: 1,
    descricao_fisica: descricao,
    estado_saude: saude,
  });
}
export function lerDescricao(value: string): {
  descricao_fisica: string;
  estado_saude: string;
} {
  try {
    const d = JSON.parse(value);
    if (
      d.miar === 1 &&
      typeof d.descricao_fisica === 'string' &&
      typeof d.estado_saude === 'string'
    )
      return {
        descricao_fisica: d.descricao_fisica,
        estado_saude: d.estado_saude,
      };
  } catch {
    /* descricoes simples do DER continuam legiveis */
  }
  return { descricao_fisica: value, estado_saude: '' };
}
