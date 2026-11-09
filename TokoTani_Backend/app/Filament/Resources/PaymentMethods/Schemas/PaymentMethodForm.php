<?php

namespace App\Filament\Resources\PaymentMethods\Schemas;

use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class PaymentMethodForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('nama')
                    ->label('Nama Metode Pembayaran')
                    ->required()
                    ->maxLength(255),
                Textarea::make('deskripsi')
                    ->label('Deskripsi / Petunjuk Transfer')
                    ->nullable()
                    ->columnSpanFull(),
                Toggle::make('aktif')
                    ->label('Status Aktif')
                    ->default(true),
            ]);
    }
}
