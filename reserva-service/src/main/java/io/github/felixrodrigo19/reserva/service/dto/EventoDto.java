package io.github.felixrodrigo19.reserva.service.dto;

import java.util.UUID;

public record EventoDto(UUID id, String nome, String descricao, String local) {
}
