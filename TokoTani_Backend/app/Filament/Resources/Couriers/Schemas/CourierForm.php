<?php

namespace App\Filament\Resources\Couriers\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class CourierForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('nama')
                    ->label('Nama Kurir')
                    ->required()
                    ->maxLength(255),
                TextInput::make('tarif')
                    ->label('Tarif Pengiriman')
                    ->required()
                    ->numeric()
                    ->prefix('Rp')
                    ->minValue(0),
                Toggle::make('aktif')
                    ->label('Status Aktif')
                    ->default(true),
            ]);
    }
}
