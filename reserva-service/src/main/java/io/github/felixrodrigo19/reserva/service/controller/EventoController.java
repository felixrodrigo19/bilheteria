package io.github.felixrodrigo19.reserva.service.controller;

import io.github.felixrodrigo19.reserva.service.dto.EventoDto;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/{version}/eventos")
public class EventoController {

    @GetMapping(version = "v1")
    public ResponseEntity<List<EventoDto>> getEventos() {
        return ResponseEntity.ok().body(new ArrayList<EventoDto>());
    }
}
