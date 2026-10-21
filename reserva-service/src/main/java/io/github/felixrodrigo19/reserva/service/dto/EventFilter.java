package io.github.felixrodrigo19.reserva.service.dto;

import io.github.felixrodrigo19.reserva.service.domain.shared.PageQuery;

import java.time.LocalDateTime;

public record EventFilter(String venue,
                          LocalDateTime date,
                          String name,
                          String description,
                          PageQuery pageQuery) {
}
