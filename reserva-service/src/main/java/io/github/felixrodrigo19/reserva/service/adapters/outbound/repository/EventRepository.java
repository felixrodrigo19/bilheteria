package io.github.felixrodrigo19.reserva.service.adapters.outbound.repository;

import io.github.felixrodrigo19.reserva.service.adapters.outbound.entity.EventEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.UUID;

@Repository
public interface EventRepository extends JpaRepository<EventEntity, UUID> {
    @Query(value = """
            SELECT e FROM EventEntity e
            """)
    Page<EventEntity> findByFilter(@Param("venue") String venue,
                                   @Param("date") LocalDateTime date,
                                   @Param("name") String name,
                                   @Param("description") String description,
                                   Pageable pageable);
}
