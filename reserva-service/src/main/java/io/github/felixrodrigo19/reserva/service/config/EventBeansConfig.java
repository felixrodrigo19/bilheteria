package io.github.felixrodrigo19.reserva.service.config;

import io.github.felixrodrigo19.reserva.service.adapters.outbound.repository.EventRepository;
import io.github.felixrodrigo19.reserva.service.application.usecase.SearchEvents;
import io.github.felixrodrigo19.reserva.service.domain.event.IEventRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class EventBeansConfig {

    @Bean
    public SearchEvents searchEvents(IEventRepository repository) {
        return new SearchEvents(repository);
    }
}
