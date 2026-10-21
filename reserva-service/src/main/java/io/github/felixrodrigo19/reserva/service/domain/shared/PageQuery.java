package io.github.felixrodrigo19.reserva.service.domain.shared;


public record PageQuery(int page, int size, String sortBy, boolean ascending) {
    public PageQuery {
        if (page < 1)
            throw new IllegalArgumentException("page must be greater than or equal to 1");
        if (size < 1 || size > 100)
            throw new IllegalArgumentException("size must be between 1 and 100");
    }
}
