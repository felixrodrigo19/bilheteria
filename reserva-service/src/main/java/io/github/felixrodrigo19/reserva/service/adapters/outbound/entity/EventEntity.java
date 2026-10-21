package io.github.felixrodrigo19.reserva.service.adapters.outbound.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "evento")
public class EventEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @Column(name = "nome", nullable = false, length = 200)
    private String name;

    @Column(name = "descricao")
    private String description;

    @Column(name = "local", nullable = false, length = 200)
    private String venue;

    @Column(name = "criado_em", nullable = false)
    private LocalDateTime createdAt;

    public UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }

    public String getVenue() {
        return venue;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
