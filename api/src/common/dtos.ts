import { BadRequestException } from '@nestjs/common';
import { plainToInstance, Transform, Type } from 'class-transformer';
import {
  IsArray,
  IsEmail,
  IsIn,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
  validate,
} from 'class-validator';

export const PERFIS = ['Cidadão', 'Protetor independente', 'ONG'] as const;
export const PORTES = ['Pequeno', 'Médio', 'Grande'] as const;
export const STATUS = [
  'Perdido',
  'Encontrado',
  'Emergência',
  'Aguardando Adoção',
  'Adotado',
  'Resgatado',
] as const;
const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;
export function telefoneBR(value: string): string {
  let digits = value.replace(/\D/g, '');
  if ((digits.length === 12 || digits.length === 13) && digits.startsWith('55'))
    digits = digits.slice(2);
  const ddds =
    '11 12 13 14 15 16 17 18 19 21 22 24 27 28 31 32 33 34 35 37 38 41 42 43 44 45 46 47 48 49 51 53 54 55 61 62 63 64 65 66 67 68 69 71 73 74 75 77 79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99'.split(
      ' ',
    );
  if (
    !ddds.includes(digits.slice(0, 2)) ||
    !/^(\d{2}[2-5]\d{7}|\d{2}9\d{8})$/.test(digits)
  )
    throw new BadRequestException(
      'Informe um telefone brasileiro válido com DDD.',
    );
  return digits;
}
export class LoginDto {
  @Transform(trim)
  @IsEmail({}, { message: 'E-mail inválido.' })
  @MaxLength(160)
  email!: string;
  @IsString()
  @IsNotEmpty({ message: 'Informe a senha.' })
  @MaxLength(256)
  senha!: string;
}
export class CadastroDto extends LoginDto {
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(120) nome!: string;
  @IsString() @MaxLength(30) telefone!: string;
  @IsIn(PERFIS) tipo_usuario!: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(30) documento?: string;
}
export class PerfilDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  nome?: string;
  @IsOptional() @Transform(trim) @IsEmail() @MaxLength(160) email?: string;
  @IsOptional() @IsString() @MaxLength(30) telefone?: string;
  @IsOptional() @IsString() @IsNotEmpty() @MaxLength(256) senha?: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(30) documento?: string;
}
export class LocalizacaoDto {
  @IsLatitude() latitude!: number;
  @IsLongitude() longitude!: number;
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(100) cidade!: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(2) estado?: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(200) endereco?: string;
}
export class OcorrenciaDto {
  @IsOptional() @IsArray() @IsInt({ each: true }) fotos_mantidas?: number[];
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(40) especie!: string;
  @IsIn(PORTES) porte!: string;
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  estado_saude!: string;
  @IsIn(STATUS) status_ocorrencia!: string;
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(5000)
  descricao_fisica!: string;
  @ValidateNested() @Type(() => LocalizacaoDto) localizacao!: LocalizacaoDto;
  @IsString() @MaxLength(30) numero_whatsapp!: string;
}
export class FiltrosDto {
  @IsOptional() @IsIn(STATUS) status?: string;
  @IsOptional() @IsString() @MaxLength(40) especie?: string;
  @IsOptional() @IsString() @MaxLength(20) porte?: string;
  @IsOptional() @IsString() @MaxLength(100) cidade?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) pagina = 0;
}
export class StatusDto {
  @IsIn(STATUS) status_ocorrencia!: string;
}
export async function parseOcorrencia(value: string): Promise<OcorrenciaDto> {
  let data: unknown;
  try {
    data = JSON.parse(value);
  } catch {
    throw new BadRequestException('Dados da ocorrência inválidos.');
  }
  if (!data || typeof data !== 'object' || Array.isArray(data))
    throw new BadRequestException('Dados da ocorrência inválidos.');
  const dto = plainToInstance(OcorrenciaDto, data);
  const errors = await validate(dto, {
    whitelist: true,
    forbidNonWhitelisted: true,
    forbidUnknownValues: true,
  });
  if (errors.length || !dto.localizacao)
    throw new BadRequestException(
      'Confira os campos da ocorrência, cidade e coordenadas GPS.',
    );
  telefoneBR(dto.numero_whatsapp);
  return dto;
}
